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

// =============================================
// Creates an instance of the model and opens
// the database with set name so that the same
// database is opened every time the app starts.
// =============================================
-(id)init {
    self = [super init];
    if (self) {

        _interfaceQueue = dispatch_queue_create("interfaceThread", DISPATCH_QUEUE_SERIAL);

        // All interactions with the database interface must be synchronous,
        // so they take the following form.
        dispatch_block_t block = ^{
            self.dbInterface = [[DBInterface alloc] init];
        };
        dispatch_sync(self.interfaceQueue, block);
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];

        __block NSString *dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:DATABASE_NAME]];
        block = ^{
            dbfs = [self.dbInterface openDatabase:dbPath];
        };
        dispatch_sync(self.interfaceQueue, block);

    }

    return self;
}

// =============================================
// Retrieves the error message corresponding to
// a given error number.
// =============================================
-(NSString *)dbError:(int)err {
    
    __block NSString *r = 0;
    __block int err_t = err;
    dispatch_block_t block = ^{
        r = [self.dbInterface dbError:err_t];
    };
    dispatch_sync(self.interfaceQueue, block);

    return r;

}

// =============================================
// Closes the database synchronously.
// =============================================
-(void)closeDatabase {

    dispatch_block_t block = ^{
        [self.dbInterface closeDatabase:dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

}

// =============================================
// Restarts the database.
// Deletes all database content and creates an
// empty one.
// =============================================
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
        dispatch_sync(self.interfaceQueue, block);

    }

}

// =============================================
// Writes the concent of a given file to a file
// stream.
// Returns an error number or OK.
// =============================================
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
        result = [self.dbInterface getFile:fname_t
                              fromDatabase:self->dbfs
                                        to:out_t
                                  withSize:size_t];
    };
    dispatch_sync(self.interfaceQueue, block);

    return result;

}

// =============================================
// Returns an NSData object containing the data
// from a given file.
// =============================================
-(NSData *)getFile_NSDATA:(NSString *)fname{
    if (fname == nil) {
        return nil;
    }
    else if ([fname isEqualToString:@""]) {
        return nil;
    }
    __block NSData *result = nil;
    __block NSString *fname_t = fname.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface getFile_NSDATA:fname_t
                                     fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Inserts a file into the database using a file
// stream.
// =============================================
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
        result =  [self.dbInterface putFile:fname_t
                               fromDatabase:self->dbfs
                                       from:in_t
                                   withSize:size_t];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;

}

// =============================================
// Inserts a file into the database from the
// content of an NSData object.
// =============================================
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
        result = [self.dbInterface putFile_NSDATA:fname_t
                                             Blob:myData
                                     fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Replaces the contents of a given file using a
// file stream.
// =============================================
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
        result = [self.dbInterface overwriteFile:fname_t
                                      inDatabase:self->dbfs
                                            from:in_t];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Replaces the content of a given file with the
// content of a given NSData object.
// =============================================
-(int)overwriteFile_NSDATA:(NSString *)fname BLOB: (NSData*) blob {
    if (fname == nil) {
        return DBFS_NOT_FILENAME;
    }
    else if ([fname isEqualToString:@""]) {
        return DBFS_NOT_FILENAME;
    }
    __block int result = DBFS_LIGHTS_ON;
    __block NSString *fname_t = fname.copy;
    dispatch_block_t block = ^{
        result = [self.dbInterface overwriteFile_NSDATA:fname_t
                                                   Blob:blob
                                           fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Changes the pathname of a file.
// =============================================
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
        result = [self.dbInterface renameFile:oldName_t
                                           to:newName_t
                                 fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

    return result;

}

// =============================================
// Changes the pathname of a file.
// =============================================
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
        result = [self.dbInterface renameFile:oldName_t
                                           to:newName_t
                                 fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Removes a given file from the database.
// =============================================
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
        result = [self.dbInterface deleteFile:fname_t
                                 fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;

}

// =============================================
// Creates an empty directory with the given
// full path name.
// =============================================
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
        result = [self.dbInterface createDirectory:dirName_t
                                      fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;

}

// ==============================================
// Removes the given directory from the database.
// Also removes all contents and subdirectories.
// ==============================================
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
        result = [self.dbInterface deleteDirectory:dirName_t
                                      fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Changes the path of a given directory.
// Also moves all content.
// =============================================
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
        result = [self.dbInterface moveDirectory:dirName_t
                                              to:destName_t
                                    fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;

}

// =============================================
// Changes the path name of a given directory.
// =============================================
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
        result = [self.dbInterface moveDirectory:dirName_t
                                              to:newName_t
                                    fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);
    return result;
}

// =============================================
// Creates an alphabetized array of the files
// in the given directory.
// =============================================
-(NSArray *)getFileArrayIn:(NSString *)dirName {
    __block DBFS_FileList fileList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        fileList = [self.dbInterface getFileListIn:dirName_t
                                      fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    // First create a dictionary of the files with the names as keys
    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                           [[NSNumber alloc] initWithBool:NO], @"type",
                           [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"size",
                           [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"modified",
                           nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((fileList.files)+i)->name]];
        [fileDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    // Then alphabetize the keys
    NSArray *alphabeticalKeys = [[fileDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // And create an array of just the files according to the order of the keys
    NSArray *objects = [fileDict objectsForKeys:alphabeticalKeys
                                 notFoundMarker:[NSNull null]];
    
    return objects;
}

// ================================================
// Creates an alphabetized array of the directories
// in the given directory.
// ================================================
-(NSArray *)getDirectoryArrayIn:(NSString *)dirName {
    __block DBFS_DirList dirList;
    NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        dirList = [self.dbInterface getDirectoryListIn:dirName_t
                                            inDatabase:dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    // First create a dictionary of the directories with their names as keys
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                           [[NSNumber alloc] initWithBool:YES], @"type",
                           [[NSNumber alloc] initWithInt:0], @"size",
                           @"", @"modified", nil];
        NSString *s = [NSString stringWithUTF8String:((dirList.dirs)+i)->name];
        [keys addObject:[[NSString alloc] initWithString:s]];
        [dirDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    // Then alphabetize the keys
    NSArray *alphabeticalKeys = [[dirDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // And create an array of the directories according to the keys
    NSArray *objects = [dirDict objectsForKeys:alphabeticalKeys
                                notFoundMarker:[NSNull null]];

    return objects;
}

// ===============================================
// Creates an array of the contents of the given
// directory. Starts with alphabetical directories
// followed by alphabetical files.
// ===============================================
-(NSArray *)getContentsArrayIn:(NSString *)dirName {
    NSMutableArray *contentArray = [[NSMutableArray alloc] initWithArray:[self getDirectoryArrayIn:dirName]];
    NSArray *tempArray = [self getFileArrayIn:dirName];
    [contentArray addObjectsFromArray:tempArray];
    return contentArray;
}

// ===============================================
// Creates an alphabetical dictionary of the files
// in a given directory. File names as keys.
// ===============================================
-(NSDictionary *)getFileListIn:(NSString *)dirName {
    __block DBFS_FileList fileList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        fileList = [self.dbInterface getFileListIn:dirName_t
                                      fromDatabase:self->dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

    NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    // First create a dictionary of the files
    for (int i = 0; i < fileList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((fileList.files)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                           [[NSNumber alloc] initWithBool:NO], @"type",
                           [[NSNumber alloc] initWithInt:((fileList.files)+i)->size], @"size",
                           [[NSNumber alloc] initWithInt:((fileList.files)+i)->timestamp ], @"modified", nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((fileList.files)+i)->name]];
        [fileDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    // Then alphabetize the keys
    NSArray *alphabeticalKeys = [[fileDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // Then create an array of the files based on the ordered keys
    NSArray *objects = [fileDict objectsForKeys:alphabeticalKeys
                                 notFoundMarker:[NSNull null]];
    // Finally, recreate the dictionary based on the alphabetical array.
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects
                                                            forKeys:alphabeticalKeys];
    
    return finalDict;
}

// =============================================
// Creates an alphabetical dictionary of the
// directories in a given directory.
// =============================================
-(NSDictionary *)getDirectoryListIn:(NSString *)dirName {
    __block DBFS_DirList dirList;
    __block NSString *dirName_t = dirName.copy;
    dispatch_block_t block = ^{
        dirList = [self.dbInterface getDirectoryListIn:dirName_t
                                            inDatabase:dbfs];
    };
    dispatch_sync(self.interfaceQueue, block);

    NSMutableDictionary *dirDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
 
	// First create a dictionary of the directories
    for (int i = 0; i < dirList.count; i++) {
        NSString *name = [[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name];
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name",
                           [[NSNumber alloc] initWithBool:YES], @"type",
                           [[NSNumber alloc] initWithInt:0], @"size",
                           @"", @"modified",
                           nil];
        
        [keys addObject:[[NSString alloc] initWithUTF8String:((dirList.dirs)+i)->name]];
        [dirDict setObject:d forKey:[keys objectAtIndex:i]];
    }
    
    // Then alphabetize the keys 
    NSArray *alphabeticalKeys = [[dirDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    // And create an array based on the ordered keys
    NSArray *objects = [dirDict objectsForKeys:alphabeticalKeys
                                notFoundMarker:[NSNull null]];
	// Finally, recreate the dictionary from the ordered array
    NSDictionary *finalDict = [[NSDictionary alloc] initWithObjects:objects
                                                            forKeys:alphabeticalKeys];
    return finalDict;
}

// =============================================
// Creates an alphabetical dictionary with all
// the contents of the given directory. Starts 
// with directories followed by files.
// =============================================
-(NSDictionary *)getContentsIn:(NSString *)dirName {
    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] initWithDictionary:[self getDirectoryListIn:dirName]];
    NSDictionary *tempDict = [self getFileListIn:dirName];
    [contentDict addEntriesFromDictionary:tempDict];
    return contentDict;
}

-(NSData *)getJsonContentsIn:(NSString *)dirName {
    
    NSArray *contentArray = [self getContentsArrayIn:dirName];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:contentArray, @"contents", nil];
    NSData *contents = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:nil];
    return contents;

}

@end