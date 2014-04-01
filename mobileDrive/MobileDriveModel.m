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

-(id)init {
    self = [super init];
    dbfs = [dbInterface openDatabase:@"database"];
    
    return self;
}

-(NSDictionary *)getCurrentContents {
    return _directoryContents;
}


-(DBFS_Blob)slurp:(FILE *)in {
    DBFS_Blob blob;
    
    return blob;
}

-(int)getFile:(NSString *)fname to:(FILE *)out withSize:(int *)size {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    int result = [dbInterface getFile:fname fromDatabase:self->dbfs to:out withSize:size];
    
    return result;
}

-(int)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [dbInterface putFile:fname fromDatabase:self->dbfs from:in withSize:size];
    
}

-(int)renameFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self->dbInterface renameFile:oldName to:newName fromDatabase:self->dbfs];
}

-(int)moveFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self->dbInterface renameFile:oldName to:newName fromDatabase:self->dbfs];
}

-(int)overwriteFile:(NSString *)fname from:(FILE *)in {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return[dbInterface overwriteFile:fname inDatabase:self->dbfs from:in];
}

-(int)deleteFile:(NSString *)fname {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [dbInterface deleteFile:fname fromDatabase:self->dbfs];
}

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName {
    if (dirName == nil || destName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [destName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [dbInterface moveDirectory:dirName to:destName fromDatabase:self->dbfs];
}

-(int)renameDirectory:(NSString *)dirName to:(NSString *)newName {
    if (dirName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [dbInterface moveDirectory:dirName to:newName fromDatabase:self->dbfs];
}

-(NSDictionary *)getFileListIn:(NSString *)dirName {
    DBFS_FileList *fileList = nil;
    fileList = [dbInterface getFileListIn:dirName fromDatabase:self->dbfs];
    
    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    for (int i = 0; i < fileList->count; i++) {
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithBool:NO], @"Type", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((fileList->files)+i)->name]];
        [fileDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the file list */
    NSArray *alphabeticalKeys = [[fileDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [fileDict objectsForKeys:alphabeticalKeys notFoundMarker:nil];
    
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
    
    return finalDict;
}

-(NSDictionary *)getDirectoryListIn:(NSString *)dirName {
    DBFS_DirList *dirList = nil;
    dirList = [dbInterface getDirectoryListIn:dirName inDatabase:dbfs];
    
    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
 
    for (int i = 0; i < dirList->count; i++) {
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithBool:YES], @"Type", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((dirList->dirs)+i)->name]];
        [dirDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the directory list */
    NSArray *alphabeticalKeys = [[dirDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [dirDict objectsForKeys:alphabeticalKeys notFoundMarker:nil];
    
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
    
    return finalDict;
}

-(NSDictionary *)getContentsIn:(NSString *)dirName {
    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDirectoryListIn:dirName]];
    
    NSDictionary *tempDict = [self getFileListIn:dirName];
    
    [contentDict addEntriesFromDictionary:tempDict];
    
    return contentDict;
}


@end
