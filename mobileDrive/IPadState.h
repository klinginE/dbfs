//
//  IPadState.h
//  mobileDrive
//
//  Created by Eric Bryan Klinginsmith on 4/17/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPadState : NSObject

@property (strong, atomic) NSString *currentDir;
@property (strong, atomic) NSString *currentPath;
@property (strong, atomic) NSString *ipAddress;
@property (strong, atomic) NSString *port;
@property (assign, atomic) NSInteger depth;

-(id)initWithPath:(NSString *)path Address:(NSString *)ipAddress Port:(NSString *)port;

@end