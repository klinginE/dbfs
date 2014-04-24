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
    __block DBFS *dbfs;

}

-(id)init {
    self = [super init];
    if (self) {

        _interfaceQueue = dispatch_queue_create("interfaceThread", DISPATCH_QUEUE_SERIAL);
        //_interfaceLock = [[NSLock alloc] init];

        dispatch_block_t block = ^{
            self.dbInterface = [[DBInterface alloc] init];
        };
        //[self.interfaceLock lock];
        dispatch_sync(self.interfaceQueue, block);
        //[self.interfaceLock unlock];

//        [block1 performSelector:@selector(invoke) onThread:self.interfaceThread withObject:nil waitUntilDone:YES];
        //[self.interfaceThread ]
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];

        __block NSString *dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:DATABASE_NAME]];
        block = ^{
            dbfs = [self.dbInterface openDatabase:dbPath];
        };
        //[self.interfaceLock lock];
        dispatch_sync(self.interfaceQueue, block);
        //[self.interfaceLock unlock];

    }

    return self;
}

-(NSString *)dbError:(int)err {
    
    __block NSString *r = 0;
    __block int err_t = err;
    dispatch_block_t block = ^{
        r = [self.dbInterface dbError:err_t];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    return r;

}

-(void)closeDatabase {

    dispatch_block_t block = ^{
        [self.dbInterface closeDatabase:dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

}

-(void)deleteDatabaseRecreate:(BOOL)flag {

    [self closeDatabase];
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:DATABASE_NAME]];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    __autoreleasing NSError *error;
    [fileMgr removeItemAtPath:dbPath error:&error];

    if (error) {

        NSLog(@"Fatal error in removing database: %@ because: %@", dbPath, [error description]);
        abort();

    }

    if (flag) {
    
        __block NSString *dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:DATABASE_NAME]];
        dispatch_block_t block = ^{
            dbfs = [self.dbInterface openDatabase:dbPath];
        };
        //[self.interfaceLock lock];
        dispatch_sync(self.interfaceQueue, block);
        //[self.interfaceLock unlock];

    }

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
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
    __block FILE *out_t = out;
    __block int *size_t = size;
    dispatch_block_t block = ^{
        result = [self.dbInterface getFile:fname_t fromDatabase:self->dbfs to:out_t withSize:size_t];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

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
    __block NSData *result = nil;
    __block NSString *fname_t = fname.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface getFile_NSDATA:fname_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(int)putFile:(NSString *)fname from:(FILE *)in withSize:(int)size {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
    __block FILE *in_t = in;
    __block int size_t = size;
    dispatch_block_t block = ^{
        result =  [self.dbInterface putFile:fname_t fromDatabase:self->dbfs from:in_t withSize:size_t];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;

}
-(int)overwriteFile_NSDATA:(NSString *)fname BLOB: (NSData*) blob {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
//    __block FILE *in_t = in;
    dispatch_block_t block = ^{
        result = [self.dbInterface overwriteFile_NSDATA:fname_t Blob:blob fromDatabase:self->dbfs];
//        result = [self.dbInterface overwriteFile_NSDATA:fname_t inDatabase:self->dbfs from:in_t];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(int)putFile_NSDATA:(NSString *)fname BLOB: (NSData*) blob {
    if (fname == nil || blob == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSData * myData = blob;
    __block NSString *fname_t = fname.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface putFile_NSDATA:fname_t Blob:myData fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(int)renameFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *oldName_t = oldName.copy;
    __block NSString *newName_t = newName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface renameFile:oldName_t to:newName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    return result;

}

-(int)moveFile:(NSString *)oldName to:(NSString *)newName {
    if (oldName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([oldName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *oldName_t = oldName.copy;
    __block NSString *newName_t = newName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface renameFile:oldName_t to:newName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(int)overwriteFile:(NSString *)fname from:(FILE *)in {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
    __block FILE *in_t = in;
    dispatch_block_t block = ^{
        result = [self.dbInterface overwriteFile:fname_t inDatabase:self->dbfs from:in_t];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;

}

-(int)deleteFile:(NSString *)fname {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface deleteFile:fname_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;

}

-(int)createDirectory:(NSString *)dirName {
    if (dirName == nil) {
        return DBFS_NOT_DIRNAME;
    }
    else if ([dirName isEqualToString:@""]) {
        return DBFS_NOT_DIRNAME;
    }
    
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface createDirectory:dirName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;

}

-(int)deleteDirectory:(NSString *)dirName {
    if (dirName == nil) {
        return DBFS_NOT_DIRNAME;
    }
    else if ([dirName isEqualToString:@""]) {
        return DBFS_NOT_DIRNAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface deleteDirectory:dirName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(int)moveDirectory:(NSString *)dirName to:(NSString *)destName {
    if (dirName == nil || destName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [destName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *dirName_t = dirName.copy;
    __block NSString *destName_t = destName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface moveDirectory:dirName_t to:destName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;

}

-(int)renameDirectory:(NSString *)dirName to:(NSString *)newName {
    if (dirName == nil || newName == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([dirName isEqualToString:@""] || [newName isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *dirName_t = dirName.copy;
    __block NSString *newName_t = newName.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface moveDirectory:dirName_t to:newName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];
    return result;
}

-(NSArray *)getFileArrayIn:(NSString *)dirName {
    __block DBFS_FileList fileList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        fileList = [self.dbInterface getFileListIn:dirName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", [[NSNumber alloc] initWithBool:NO], @"type", [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"size", [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"modified", nil];
        
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
    __block DBFS_DirList dirList;
    NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        dirList = [self.dbInterface getDirectoryListIn:dirName_t inDatabase:dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", [[NSNumber alloc] initWithBool:YES], @"type", [[NSNumber alloc] initWithInt:0], @"size", @"", @"modified", nil];
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
    __block DBFS_FileList fileList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        fileList = [self.dbInterface getFileListIn:dirName_t fromDatabase:self->dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", [[NSNumber alloc] initWithBool:NO], @"type", [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"size", [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"modified", nil];
        
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
    __block DBFS_DirList dirList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        dirList = [self.dbInterface getDirectoryListIn:dirName_t inDatabase:dbfs];
    };
    //[self.interfaceLock lock];
    dispatch_sync(self.interfaceQueue, block);
    //[self.interfaceLock unlock];

    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
 
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", [[NSNumber alloc] initWithBool:YES], @"type", [[NSNumber alloc] initWithInt:0], @"size", @"", @"modified", nil];
        
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

-(NSData *)getJsonContentsIn:(NSString *)dirName {
    
    NSArray *contentArray = [self getContentsArrayIn:dirName];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:contentArray, @"contents", nil];
    NSData *contents = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *s = [[NSString alloc] initWithBytes:[contents bytes] length:[contents length] encoding:NSUTF8StringEncoding];
    NSLog(@"JSON contents: %@", s);
    return contents;
    
    /*
    
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
     */
}

@end