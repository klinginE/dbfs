//
//  MobileDriveModel.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/11/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "MobileDriveModel.h"


@implementation MobileDriveModel {
    NSDictionary *_directoryContents;
    NSArray *_directoryKeys;
    DBFS *dbfs;
}

-(id)init {
    self = [super init];
    if (self) {

        self.dbInterface = [[DBInterface alloc] init];
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"database.sqlite"]];
        dbfs = [self.dbInterface openDatabase:dbPath];

    }

    return self;
}

-(NSString *)dbError:(int)err {
    return [self.dbInterface dbError:err];
}

-(void)closeDatabase {
    [self.dbInterface closeDatabase:dbfs];
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
    int result = [self.dbInterface getFile:fname fromDatabase:self->dbfs to:out withSize:size];
    
    return result;
}

-(NSData *)getFile_NSDATA:(NSString *)fname{
    if (fname == nil) {
//        return DBFS_NOT_FILENAME;
        return nil;
    }
    else if ([fname isEqualToString:@""]) {
//        return DBFS_NOT_FILENAME;
        return nil;
    }
//    int result = [self.dbInterface getFile:fname fromDatabase:self->dbfs to:out withSize:size];
    
    return [self.dbInterface getFile_NSDATA:fname fromDatabase:self->dbfs];
}

-(int)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface putFile:fname fromDatabase:self->dbfs from:in withSize:size];
    
}

-(int)renameFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface renameFile:oldName to:newName fromDatabase:self->dbfs];
}

-(int)moveFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface renameFile:oldName to:newName fromDatabase:self->dbfs];
}

-(int)overwriteFile:(NSString *)fname from:(FILE *)in {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return[self.dbInterface overwriteFile:fname inDatabase:self->dbfs from:in];
}

-(int)deleteFile:(NSString *)fname {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface deleteFile:fname fromDatabase:self->dbfs];
}

-(int)createDirectory:(NSString *)dirName {
    if (dirName == nil) {
        return DBFS_NOT_DIRNAME;
    }
    else if ([dirName isEqualToString:@""]) {
        return DBFS_NOT_DIRNAME;
    }
    return [self.dbInterface createDirectory:dirName fromDatabase:self->dbfs];
}

-(int)deleteDirectory:(NSString *)dirName {
    if (dirName == nil) {
        return DBFS_NOT_DIRNAME;
    }
    else if ([dirName isEqualToString:@""]) {
        return DBFS_NOT_DIRNAME;
    }
    return [self.dbInterface deleteDirectory:dirName fromDatabase:self->dbfs];
}

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName {
    if (dirName == nil || destName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [destName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface moveDirectory:dirName to:destName fromDatabase:self->dbfs];
}

-(int)renameDirectory:(NSString *)dirName to:(NSString *)newName {
    if (dirName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    return [self.dbInterface moveDirectory:dirName to:newName fromDatabase:self->dbfs];
}

-(NSArray *)getFileArrayIn:(NSString *)dirName {
    DBFS_FileList fileList;
    fileList = [self.dbInterface getFileListIn:dirName fromDatabase:self->dbfs];
    
    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", [[NSNumber alloc] initWithBool:NO], @"Type", [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"Size", [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"Modified", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((fileList.files)+i)->name]];
        [fileDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the file list */
    NSArray *alphabeticalKeys = [[fileDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [fileDict objectsForKeys:alphabeticalKeys notFoundMarker:[NSNull null]];
    
    //    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
    
    return objects;
}

-(NSArray *)getDirectoryArrayIn:(NSString *)dirName {
    DBFS_DirList dirList;
    dirList = [self.dbInterface getDirectoryListIn:dirName inDatabase:dbfs];
    
    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", [[NSNumber alloc] initWithBool:YES], @"Type", [[NSNumber alloc] initWithInt:0], @"Size", @"", @"Modified", nil];
        NSString *s = [NSString stringWithUTF8String:((dirList.dirs)+i)->name];
        [keys addObject:[[NSString alloc] initWithString:s]];
        [dirDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the directory list */
    
    NSArray *alphabeticalKeys = [[dirDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [dirDict objectsForKeys:alphabeticalKeys notFoundMarker:[NSNull null]];
    
    //    NSLog(@"keys: %@", alphabeticalKeys);
    
    //    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
    //    NSLog(@"final: %@", finalDict);
    return objects;
}

-(NSArray *)getContentsArrayIn:(NSString *)dirName {
    NSMutableArray *contentArray = [[NSMutableArray alloc] initWithArray:[self getDirectoryArrayIn:dirName]];
    //    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDirectoryListIn:dirName]];
    NSArray *tempArray = [self getFileArrayIn:dirName];
    //    NSDictionary *tempDict = [self getFileListIn:dirName];
    [contentArray addObjectsFromArray:tempArray];
    //    [contentDict addEntriesFromDictionary:tempDict];
    return contentArray;
}


-(NSDictionary *)getFileListIn:(NSString *)dirName {
    DBFS_FileList fileList;
    fileList = [self.dbInterface getFileListIn:dirName fromDatabase:self->dbfs];
    
    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", [[NSNumber alloc] initWithBool:NO], @"Type", [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"Size", [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"Modified", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((fileList.files)+i)->name]];
        [fileDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the file list */
    NSArray *alphabeticalKeys = [[fileDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [fileDict objectsForKeys:alphabeticalKeys notFoundMarker:[NSNull null]];
    
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
    
    return finalDict;
}

-(NSDictionary *)getDirectoryListIn:(NSString *)dirName {
    DBFS_DirList dirList;
    dirList = [self.dbInterface getDirectoryListIn:dirName inDatabase:dbfs];
    
    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
 
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", [[NSNumber alloc] initWithBool:YES], @"Type", [[NSNumber alloc] initWithInt:0], @"Size", @"", @"Modified", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name]];
        [dirDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    /* Alphabetize the directory list */
    
    NSArray *alphabeticalKeys = [[dirDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *objects = [dirDict objectsForKeys:alphabeticalKeys notFoundMarker:[NSNull null]];
    
//    NSLog(@"keys: %@", alphabeticalKeys);
    
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects forKeys:alphabeticalKeys];
//    NSLog(@"final: %@", finalDict);
    return finalDict;
}

-(NSDictionary *)getContentsIn:(NSString *)dirName {
//    NSMutableArray *contentArray = [[NSMutableArray alloc] initWithArray:[self getDirectoryListIn:dirName]];
    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDirectoryListIn:dirName]];
//    NSLog(@"init: %@", contentArray);
//    NSArray *tempArray = [self getFileListIn:dirName];
    NSDictionary *tempDict = [self getFileListIn:dirName];
//    [contentArray addObjectsFromArray:tempArray];
    [contentDict addEntriesFromDictionary:tempDict];
//    NSLog(@"last: %@", contentArray);
    return contentDict;
}

-(NSString *)getJsonContentsIn:(NSString *)dirName {
    NSString *temp = @"{\n\t\"contents\": [";
    NSString *json = [[NSString alloc] initWithString:temp];
    NSArray *dict = [self getContentsArrayIn:dirName];
//    NSArray *keys = [dict allKeys];
    for (NSUInteger i = 0; i < [dict count]; ++i) {
//        NSString *name = [keys objectAtIndex:i];
        NSString *name = [[dict objectAtIndex:i] objectForKey:@"Name"];
        json = [json stringByAppendingString:@"\n\t\t{\n\t\t\t\"name\": \""];
        json = [json stringByAppendingString:name];
        json = [json stringByAppendingString:@"\",\n\t\t\t\"size\": \""];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"%@", [[dict objectAtIndex:i] objectForKey:@"Size"]]];
//        json = [json stringByAppendingString:[NSString stringWithFormat:@"%@", [[dict objectForKey:name] objectForKey:@"Size"]]];
        json = [json stringByAppendingString:@"\",\n\t\t\t\"modified\": \""];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"%@", [[dict objectAtIndex:i] objectForKey:@"Modified"]]];
        
        json = [json stringByAppendingString:@"\"\n\t\t}"];
        if (i < [dict count] - 1) {
            json = [json stringByAppendingString:@","];
        }
    }
    
    json = [json stringByAppendingString:@"\n\t]\n}"];
    return json;
}


@end
