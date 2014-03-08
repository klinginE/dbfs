//
//  MobileDriveAppDelegate.h
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MobileDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (atomic) BOOL isConnected;

@end