//
//  DBInterface.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "dbfs.h"

@interface DBInterface : NSObject

-(const char *)nsStringToCString:(NSString *)s;
-(DBFS_Blob)slurp:(FILE *)in;
-(NSString *)dbError:(int)err;
-(DBFS *)openDatabase:(NSString *)name;
-(void)closeDatabase:(DBFS *)dbfs;
-(int)getFile:(NSString *)fname fromDatabase:(DBFS *)dbfs to:(FILE *)out withSize:(int *)size;
-(int)putFile:(NSString *)fname fromDatabase:(DBFS *)dbfs from:(FILE *)in withSize:(int)size;
-(int)overwriteFile:(NSString *)fname inDatabase:(DBFS *)dbfs from:(FILE *)in;
-(int)deleteFile:(NSString *)fname fromDatabase:(DBFS *)dbfs;
-(int)renameFile:(NSString *)oldName to:(NSString *)newName fromDatabase:(DBFS *)dbfs;
-(int)createDirectory:(NSString *)dirName fromDatabase:(DBFS *)db;
-(int)deleteDirectory:(NSString *)dirName fromDatabase:(DBFS *)dbfs;
-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName fromDatabase:(DBFS *)dbfs;
-(DBFS_FileList)getFileListIn:(NSString *)dirName fromDatabase:(DBFS *)dbfs;
-(DBFS_DirList)getDirectoryListIn:(NSString *)dirName inDatabase:(DBFS *)dbfs;
-(NSData *) getFile_NSDATA:(NSString *)fname fromDatabase:(DBFS *)dbfs;
-(int)putFile_NSDATA: (NSString *)fname Blob: (NSData*) blob fromDatabase:(DBFS *)dbfs;
    
@end
