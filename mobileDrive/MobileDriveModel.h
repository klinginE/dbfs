//
//  MobileDriveModel.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/11/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "dbfs/DBInterface.h"

@interface MobileDriveModel : NSObject

@property (strong, atomic) __block DBInterface *dbInterface;

-(DBFS_Blob)slurp:(FILE *)in;

-(id)init;

-(NSString *)dbError:(int)err;

-(void)closeDatabase;

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

-(int)createDirectory:(NSString *)dirName;

-(int)deleteDirectory:(NSString *)dirName;

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName;

-(int)renameDirectory:(NSString *)dirName to:(NSString *)destName;

-(NSDictionary *)getFileListIn:(NSString *)dirName;
-(NSDictionary *)getDirectoryListIn:(NSString *)dirName;

// Returns a dictionary containing the contents of dirName.
// Organization: directories first followed by files, both are alphabetical.
-(NSDictionary *)getContentsIn:(NSString *)dirName;

-(NSArray *)getFileArrayIn:(NSString *)dirName;
-(NSArray *)getDirectoryArrayIn:(NSString *)dirName;

// Returns a dictionary containing the contents of dirName.
// Organization: directories first followed by files, both are alphabetical.
-(NSArray *)getContentsArrayIn:(NSString *)dirName;

// Returns NSString containing the list of current contents in JSON format.
-(NSString *)getJsonContentsIn:(NSString *)dirName;
-(NSData *)getFile_NSDATA:(NSString *)fname;

@end
