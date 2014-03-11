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
}

-(NSDictionary *)getCurrentContents {
    return _directoryContents;
}



@end
