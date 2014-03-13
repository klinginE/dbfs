//
//  MobileDriveModel.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/11/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "MobileDriveModel.h"
#import "dbfs/DBInterface.h"

@implementation MobileDriveModel {
    NSDictionary *_directoryContents;
    NSArray *_directoryKeys;
    DBInterface *dbInterface;
    DBFS *dbfs;
}

-(NSDictionary *)getCurrentContents {
    return _directoryContents;
}


-(DBFS_Blob)slurp:(FILE *)in {
    DBFS_Blob blob;
    
    return blob;
}

-(void)getFile:(NSString *)fname to:(FILE *)out withSize:(int *)size {
    [dbInterface getFile:fname fromDatabase:dbfs to:out withSize:size];
}

-(void)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size {
    [dbInterface putFile:fname fromDatabase:dbfs from:in withSize:size];
}

-(void)overwriteFile:(NSString *)fname from:(FILE *)in {
    [dbInterface overwriteFile:fname inDatabase:dbfs from:in];
}

-(void)deleteFile:(NSString *)fname {
    [dbInterface deleteFile:fname fromDatabase:dbfs];
}

-(DBFS_FileList *)getFileListIn:(NSString *)dirName {
    return [dbInterface getFileListIn:dirName fromDatabase:dbfs];
}

-(DBFS_DirList *)getDirectoryListIn:(NSString *)dirName {
    return [dbInterface getDirectoryListIn:dirName inDatabase:dbfs];
}


@end
