//
//  DBInterface.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "DBInterface.h"

@implementation DBInterface

-(char *)nsStringToCString:(NSString *)s {
    
    int len = [s length];
    char *c = (char *)malloc(len + 1);
    int i = 0;
    for (; i < len; i++) {
        
        c[i] = [s characterAtIndex:i];
        
    }
    c[i] = '\0';
    
    return c;
    
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

-(DBFS *)openDatabase:(NSString *)name {
    char *dbName = nsStringToCString(name);
    
    DBFS *dbfs = dbfs_open(dbName);
    
    return dbfs;
}

-(void)closeDatabase:(NSString *)name {
    char *dbName = nsStringToCString(name);
    DBFS *dbfs = dbfs_close(dbName);
}

-(int)getFile:(NSString *)fname fromDatabase:(DBFS *)dbfs to:(FILE *)out withSize:(int *)size {
    
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
    int result = dbfs_get(dbfs, (DBFS_FileName){name}, &blob);
    
    if(result == DBFS_OKAY) {
        *size = blog.size;
        fwrite(blob.data, 1, blob.size, out);
    }
    return result;
}

-(int)putFile:(NSString *)fname fromDatabase:(DBFS *)dbfs from:(FILE *)in withSize:(int)size {
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
   
    blob = [self slurp:in];
    return dbfs_put(dbfs, (DBFS_FileName){name}, blob);
}

-(int)overwriteFile:(NSString *)fname inDatabase:(DBFS *)dbfs from:(FILE *)in {
    
    DBFS_Blob blob;
    char *name = [self nsStringToCString:fname];
   
    blob = [self slurp:in];
    return dbfs_ovr(dbfs, (DBFS_FileName){name}, blob);
}

-(int)deleteFile:(NSString *)fname fromDatabase:(DBFS *)dbfs {
    
    char *name = [self nsStringToCString:fname];
    return dbfs_del(dbfs, (DBFS_FileName){name});

}

// First checks to see if newName already exists.
// Asks to overwrite?
-(int)renameFile:(NSString *)fname to:(NSString *)newName fromDatabase:(DBFS *)dbfs {
	char *oldName = [self nsStringToCString:fname];
	char *name = [self nsStringToCString:newName];
    
    return dbfs_mvf(dbfs, oldName, name);
}

-(int)createDirectory:(NSString *)dirName fromDatabase:(DBFS *)db {
    char *name = [self nsStringToCString:dirName];
    return dbfs_mkd(dbfs, name);
}

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName fromDatabase:(DBFS *)dbfs{
    char *name = [self nsStringToCString:dirName];
    char *dest = [self nsStringToCString:destName];
    return dbfs_mvd(dbfs, name, dest);
}

-(DBFS_FileList *)getFileListIn:(NSString *)dirName fromDatabase:(DBFS *)dbfs {
    
    char *dname = [self nsStringToCString:dirName];
    DBFS_FileList *flist = nil;
    if (DBFS_OKAY != dbfs_lsf(dbfs, (DBFS_DirName){dname}, flist)) {
        NSLog(@"Error getting file list");
        return nil;
    }
    
    return flist;
}

-(DBFS_DirList *)getDirectoryListIn:(NSString *)dirName inDatabase:(DBFS *)dbfs {
    
    DBFS_DirList *dlist = nil;
    
    if (!dirName) {
        NSLog(@"Error: No name");
        return nil;
    }
    char *dName = [self nsStringToCString:dirName];
    if (DBFS_OKAY != dbfs_lsd(dbfs, (DBFS_DirName){dName}, dlist)) {
        NSLog(@"Error listing directories");
        return nil;
    }
    
    return dlist;
}

@end
