//
//  MobileDriveAppDelegate.h
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IPadTableViewController.h"
#import "MobileDriveModel.h"

#define PUBLIC_EXT @".pub"
#define PRIVATE_EXT @".pri"

@interface MobileDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (atomic) BOOL isConnected;
@property (strong, atomic) MobileDriveModel *model;
@property (strong, nonatomic) IPadTableViewController *iPadTableViewController;

-(void)switchChanged:(UISwitch *)sender;

@end