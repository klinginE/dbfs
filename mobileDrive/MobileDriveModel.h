//
//  MobileDriveModel.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/11/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "dbfs/DBInterface.h"
#import "dbfs/dbfs.h"

@interface MobileDriveModel : NSObject

-(DBFS_Blob)slurp:(FILE *)in;

// Retrieve contents of absolute path "fname" through file stream "out"
-(int)getFile:(NSString *)fname to:(FILE *)out withSize:(int *)size;

// Upload contents of file to absolute path "fname" through file stream "in"
-(int)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size;

// Renames the original file "oldName" the new file "newName"
// Both names are absolute paths
-(int)renameFile:(NSString *)oldName to:(NSString *)newName;
-(int)moveFile:(NSString *)oldName to:(NSString *)newName;
-(int)overwriteFile:(NSString *)fname from:(FILE *)in;

// Remove file with absolute path "fname" from database
-(int)deleteFile:(NSString *)fname;

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName;

-(int)renameDirectory:(NSString *)dirName to:(NSString *)destName;

-(NSDictionary *)getFileListIn:(NSString *)dirName;
-(NSDictionary *)getDirectoryListIn:(NSString *)dirName;
-(NSDictionary *)getContentsIn:(NSString *)dirName;

@end
