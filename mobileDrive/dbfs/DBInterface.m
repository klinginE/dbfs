//
//  DBInterface.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "DBInterface.h"

@implementation DBInterface

-(id)init {

    self = [super init];
    return self;

}

-(char *)nsStringToCString:(NSString *)s {

    return strdup([s UTF8String]);

}

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

-(NSString *)dbError:(int)err {
    NSString *error;
    const char *c = dbfs_err(err);
    error = [NSString stringWithUTF8String:c];
    return error;
}

-(DBFS *)openDatabase:(NSString *)name {
    char *dbName = [self nsStringToCString:name];
    DBFS *dbfs = dbfs_open(dbName);
    free(dbName);
    dbName = NULL;
    return dbfs;
}

-(void)closeDatabase:(DBFS *)dbfs {
    dbfs_close(dbfs);
}

-(int)getFile:(NSString *)fname fromDatabase:(DBFS *)dbfs to:(FILE *)out withSize:(int *)size {
    
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
    int result = dbfs_get(dbfs, (DBFS_FileName){name}, &blob);
    
    if(result == DBFS_OKAY) {
        *size = blob.size;
        fwrite(blob.data, 1, blob.size, out);
    }

    free(name);
    name = NULL;
    return result;
}

-(int)putFile:(NSString *)fname fromDatabase:(DBFS *)dbfs from:(FILE *)in withSize:(int)size {
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
   
    blob = [self slurp:in];
    int r = dbfs_put(dbfs, (DBFS_FileName){name}, blob);
    free(name);
    name = NULL;
    return r;
}

-(int)overwriteFile:(NSString *)fname inDatabase:(DBFS *)dbfs from:(FILE *)in {
    
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
   
    blob = [self slurp:in];
    int r = dbfs_ovr(dbfs, (DBFS_FileName){name}, blob);
    free(name);
    name = NULL;
    return r;
}

-(int)deleteFile:(NSString *)fname fromDatabase:(DBFS *)dbfs {
    
    char *name = [self nsStringToCString:fname];
    int r = dbfs_del(dbfs, (DBFS_FileName){name});
    free(name);
    name = NULL;
    return r;

}

// First checks to see if newName already exists.
// Asks to overwrite?
-(int)renameFile:(NSString *)fname to:(NSString *)newName fromDatabase:(DBFS *)dbfs {
	DBFS_FileName oldName;
    oldName.name = [fname UTF8String];
	DBFS_FileName name;
    name.name = [newName UTF8String];

    return dbfs_mvf(dbfs, oldName, name);
}

-(int)createDirectory:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    DBFS_DirName name;
    name.name = [dirName UTF8String];
    return dbfs_mkd(dbfs, name);
}

-(int)deleteDirectory:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    DBFS_DirName name;
    name.name = [dirName UTF8String];
    return dbfs_rmd(dbfs, name);
}

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName fromDatabase:(DBFS *)dbfs{
    DBFS_DirName name;
    name.name = [dirName UTF8String];
    DBFS_DirName dest;
    dest.name = [destName UTF8String];
    return dbfs_mvd(dbfs, name, dest);
}

-(DBFS_FileList)getFileListIn:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    
    char *dname = [self nsStringToCString:dirName];
    DBFS_FileList flist;
    flist.count = 0;
    flist.files = NULL;
    if (DBFS_OKAY != dbfs_lsf(dbfs, (DBFS_DirName){dname}, &flist)) {
        NSLog(@"Error getting file list");
    }
    free(dname);
    dname = NULL;
    
    return flist;
}

-(DBFS_DirList)getDirectoryListIn:(NSString *)dirName inDatabase:(DBFS *)dbfs {
    
    DBFS_DirList dlist;
    dlist.count = 0;
    dlist.dirs = NULL;
    
    if (!dirName) {
        NSLog(@"Error: No name");
        return dlist;
    }
    char *dName = [self nsStringToCString:dirName];
    if (DBFS_OKAY != dbfs_lsd(dbfs, (DBFS_DirName){dName}, &dlist)) {
        NSLog(@"Error listing directories");
    }
    free(dName);
    dName = NULL;
    return dlist;
}

@end
