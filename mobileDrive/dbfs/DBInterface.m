//
//  DBInterface.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014. All rights reserved.
//

// ========================================================================
// DBInterface.m is a wrapper class for dbfs.c and is the only way to
// interact with the database from anywhere else in the program.
// ========================================================================

#import "DBInterface.h"

@implementation DBInterface

-(id)init {

    self = [super init];
    return self;

}

// =============================================
// Converts an NSString* to a C char* string.
// =============================================
-(const char *)nsStringToCString:(NSString *)s {

    return [s UTF8String];

}

// =============================================
// Reads in data from a file stream and creates
// a DBFS_Blob containing the incoming data.
// =============================================
-(DBFS_Blob)slurp:(FILE *)in {
    uint8_t *buf = NULL;
    size_t size = 0, cap = 0;
    
    cap = 4096;
    buf = malloc(cap);
    while (true)
    {
        size_t got;
        if (size == cap)
        {
            cap *= 2;
            buf = realloc(buf, cap);
        }
        got = fread(buf + size, 1, cap - size, in);
        if (!got)
            break;
        size += got;
    }
    buf = realloc(buf, size);
    return (DBFS_Blob){buf, size};
}

// =============================================
// Takes in an error number and acquires the
// error message corresponding to that number.
// =============================================
-(NSString *)dbError:(int)err {

    NSString *error;
    const char *c = dbfs_err(err);
    error = [NSString stringWithUTF8String:c];
    return error;

}

// =============================================
// Opens the database by name, creating it if no
// such database exists.
// Returns that database.
// =============================================
-(DBFS *)openDatabase:(NSString *)name {
    const char *dbName = [self nsStringToCString:name];
    DBFS *dbfs = dbfs_open(dbName);

    return dbfs;
}

// =============================================
// Frees all the memory associated with database
// operation.
// =============================================
-(void)closeDatabase:(DBFS *)dbfs {
    dbfs_close(dbfs);
}

// =============================================
// Locates the named file in the database,
// creates a DBFS_Blob caontaining the file's
// data and writes the blob's contents to a file
// stream.
// =============================================
-(int)getFile:(NSString *)fname fromDatabase:(DBFS *)dbfs to:(FILE *)out withSize:(int *)size {
    
    DBFS_Blob blob;
    const char *name = [self nsStringToCString:fname];
    int result = dbfs_get(dbfs, (DBFS_FileName){name}, &blob);
    
    if(result == DBFS_OKAY) {
        *size = (int)blob.size;
        fwrite(blob.data, 1, blob.size, out);
        dbfs_free_blob(blob);
    }

    return result;
}

// =============================================
// Locates the named file in the database,
// creates a DBFS_Blob containing the file's
// data, and returns an NSData object with that
// content.
// =============================================
-(NSData *) getFile_NSDATA:(NSString *)fname fromDatabase:(DBFS *)dbfs{
    
    DBFS_Blob blob;
    const char *name = [fname UTF8String];
    int result = dbfs_get(dbfs, (DBFS_FileName){name}, &blob);
    
    if(result == DBFS_OKAY) {
        NSData *tempBlob = [[NSData alloc] initWithBytes:blob.data
                                                  length:blob.size];
        dbfs_free_blob(blob);
        return tempBlob;
    }
    return nil;
}

// =============================================
// Create a new file in the database with a
// given file name and data from a file stream.
// =============================================
-(int)putFile:(NSString *)fname fromDatabase:(DBFS *)dbfs from:(FILE *)in withSize:(int)size {
    DBFS_Blob blob;
    const char *name = [self nsStringToCString:fname];
   
    blob = [self slurp:in];
    int r = dbfs_put(dbfs, (DBFS_FileName){name}, blob);
    
    dbfs_free_blob(blob);

    return r;
}

// =============================================
// Create a new file in the database with a
// given file name and data from an NSData
// object.
// =============================================
-(int)putFile_NSDATA: (NSString *)fname Blob: (NSData*) blob fromDatabase:(DBFS *)dbfs{
    DBFS_Blob blob_temp = (DBFS_Blob){[blob bytes], (int) [blob length]};
    const char *name = [fname UTF8String];

    int r = dbfs_put(dbfs, (DBFS_FileName){name}, blob_temp);
    
    return r;
}

// =============================================
// Replaces the content of a named file in the
// database with that of a file stream.
// =============================================
-(int)overwriteFile:(NSString *)fname inDatabase:(DBFS *)dbfs from:(FILE *)in {
    DBFS_Blob blob;
    const char *name = [self nsStringToCString:fname];
    blob = [self slurp:in];
    int r = dbfs_ovr(dbfs, (DBFS_FileName){name}, blob);
    return r;
}

// =============================================
// Replaces the content of a named file in the
// database with that of an NSData object.
// =============================================
-(int)overwriteFile_NSDATA:(NSString *)fname Blob: (NSData*) blob fromDatabase:(DBFS *)dbfs{
    DBFS_Blob blob_temp = (DBFS_Blob){[blob bytes], (int) [blob length]};
    const char *name = [self nsStringToCString:fname];//[fname UTF8String];
    int r = dbfs_ovr(dbfs, (DBFS_FileName){name}, blob_temp);
    return r;
}

// =============================================
// Removes the named file from the database.
// =============================================
-(int)deleteFile:(NSString *)fname fromDatabase:(DBFS *)dbfs {
    
    const char *name = [self nsStringToCString:fname];//[fname UTF8String];
    int r = dbfs_del(dbfs, (DBFS_FileName){name});
    return r;

}

// ===============================================
// Changes the pathname of a file in the database.
// ===============================================
-(int)renameFile:(NSString *)fname to:(NSString *)newName fromDatabase:(DBFS *)dbfs {
	DBFS_FileName oldName;
    oldName.name = [self nsStringToCString:fname];
	DBFS_FileName name;
    name.name = [self nsStringToCString:newName];

    return dbfs_mvf(dbfs, oldName, name);
}

// =============================================
// Inserts an empty directory with the given
// path name into the database.
// =============================================
-(int)createDirectory:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    DBFS_DirName name;
    name.name = [self nsStringToCString:dirName];
    return dbfs_mkd(dbfs, name);
}

// =============================================
// Removes the named directory and all of its
// contents and subdirectories from the database.
// =============================================
-(int)deleteDirectory:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    DBFS_DirName name;
    name.name = [self nsStringToCString:dirName];
    return dbfs_rmd(dbfs, name);
}

// =============================================
// Changes the pathname of a directory.
// =============================================
-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName fromDatabase:(DBFS *)dbfs{
    DBFS_DirName name;
    name.name = [self nsStringToCString:dirName];
    DBFS_DirName dest;
    dest.name = [self nsStringToCString:destName];
    return dbfs_mvd(dbfs, name, dest);
}

// =============================================
// Returns an object with contents:
//      - list of file names
//      - list length
// in the given directory.
// =============================================
-(DBFS_FileList)getFileListIn:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    
    const char *dname = [self nsStringToCString:dirName];
    DBFS_FileList flist;
    flist.count = 0;
    flist.files = NULL;
    if (DBFS_OKAY != dbfs_lsf(dbfs, (DBFS_DirName){dname}, &flist)) {
        NSLog(@"Error getting file list");
    }
    
    return flist;
}

// =============================================
// Returns an object with contents:
//      - list of directory names
//      - list length
// in the given directory.
// =============================================
-(DBFS_DirList)getDirectoryListIn:(NSString *)dirName inDatabase:(DBFS *)dbfs {
    
    DBFS_DirList dlist;
    dlist.count = 0;
    dlist.dirs = NULL;
    
    if (!dirName) {
        NSLog(@"Error: No name");
        return dlist;
    }
    const char *dName = [self nsStringToCString:dirName];
    if (DBFS_OKAY != dbfs_lsd(dbfs, (DBFS_DirName){dName}, &dlist)) {
        NSLog(@"Error listing directories");
    }

    return dlist;
}

@end
