//
//  IPadState.m
//  mobileDrive
//
//  Created by Eric Bryan Klinginsmith on 4/17/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "IPadState.h"

@implementation IPadState

-(id)initWithPath:(NSString *)path Address:(NSString *)ipAddress Port:(NSString *)port {

    self = [super init];
    if (self) {

        _currentPath = path;
        _ipAddress = ipAddress;
        _port = port;
        NSUInteger len = [path length];
        NSUInteger index = len - 1;

        assert(len > 0);
        assert([path characterAtIndex:0] == '/');
        
        if (index)
            for (; [path characterAtIndex:index - 1] != '/'; index--);
        _currentDir = [path substringFromIndex:index];
        _depth = 0;
        for (int i = 0; i < (len - 1); i++)
            if ([path characterAtIndex:i] == '/')
                _depth++;

    }

    NSLog(@"path= %@", self.currentPath);
    NSLog(@"dir= %@", self.currentDir);
    NSLog(@"ip= %@", self.ipAddress);
    NSLog(@"port= %@", self.port);
    NSLog(@"depth= %d", self.depth);

    return self;

}

@end