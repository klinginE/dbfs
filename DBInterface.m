//
//  DBInterface.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/10/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "DBInterface.h"
#import "IPadTableViewController.h"
#import "mobileDrive/dbfs/dbfs.h"

@implementation DBInterface

//-(void)displayError:(NSString *)msg {
//    NSLog([NSString msg]);
//}

-(char *)nsStringToCString:(NSString *)s {
    
    int len = [s length];
    char *c = (char *)malloc(len + 1);
    int i = 0;
    for (; i < len; i++) {
        
        c[i] = [s characterAtIndex:i];
        
    }
    c[i] = '\0';
    
    return c;
    
}


-(int)getFile:(NSString *)fname fromDB:(DBFS *)dbfs to:(FILE *)out {
    
    char *name = [self nsStringToCString:fname];
    
    DBFS_Blob blob;
    if(!fname) {
        NSLog(@"fname missing");
        return 1;
    }
    if(DBFS_OKAY != dbfs_get(dbfs, (DBFS_FileName){name}, &blob)) {
        NSLog(@"Error getting file");
        dbfs_free_blob(blob);
        return 2;
    }
    fwrite(blob.data, 1, blob.size, out);
    dbfs_free_blob(blob);
    free(name);
    
    return 0;
}

-(int)putFile:(NSString *)

@end
