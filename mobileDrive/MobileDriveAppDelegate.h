//
//  MobileDriveAppDelegate.h
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerViewController.h"
#import "MobileDriveModel.h"

#define PUBLIC_EXT @".pub"
#define PRIVATE_EXT @".pri"

@class IPadTableViewController;
@interface MobileDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (atomic) BOOL isConnected;
@property (strong, nonatomic) UINavigationController *iPadNavController;
@property (strong, atomic) ServerViewController *serverController;
@property (strong, atomic) MobileDriveModel *model;

-(void)switchChanged:(UISwitch *)sender;
-(void)pathButtonPressed:(UIButton *)sender;
-(void)popToViewWithDepth:(NSInteger)depth Anamated:(BOOL)animate WithMessage:(NSString *)message;

@end