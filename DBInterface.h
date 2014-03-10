//
//  DBInterface.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mobileDrive/dbfs/dbfs.h"

@interface DBInterface : NSObject

-(char *)nsStringToCString:(NSString *)s;
-(DBFS_Blob)slurp:(FILE *)in;
-(int)getFile:(NSString *)fname fromDatabase:(DBFS *)dbfs to:(FILE *)out;
-(int)putFile:(NSString *)fname fromDatabase:(DBFS *)dbfs from:(FILE *)in;
-(int)overwriteFile:(NSString *)fname inDatabase:(DBFS *)dbfs from:(FILE *)in;
-(int)deleteFile:(NSString *)fname fromDB:(DBFS *)dbfs;
-(DBFS_FileList *)getFileListIn:(NSString *)dirName fromDatabase:(DBFS *)dbfs;
-(DBFS_DirList *)getDirectoryListIn:(NSString *)dirName inDatabase:(DBFS *)dbfs;

@end
