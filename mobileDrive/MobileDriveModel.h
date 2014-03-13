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
-(void)getFile:(NSString *)fname to:(FILE *)out withSize:(int *)size;

// Upload contents of file to absolute path "fname" through file stream "in"
-(void)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size;

-(void)overwriteFile:(NSString *)fname from:(FILE *)in;

// Remove file with absolute path "fname" from database
-(void)deleteFile:(NSString *)fname;

-(DBFS_FileList *)getFileListIn:(NSString *)dirName;
-(DBFS_DirList *)getDirectoryListIn:(NSString *)dirName;

@end
