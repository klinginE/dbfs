//
//  MobileDriveAppDelegate.h
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobileDriveModel.h"

#define PUBLIC_EXT @".pub"
#define PRIVATE_EXT @".pri"

typedef enum {ADD_MODEL_TAG=128, DELETE_MODEL_TAG, MOVE_MODEL_TAG, RENAME_MODEL_TAG} modelUpdateTag;

@interface MobileDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (atomic) BOOL isConnected;
@property (strong, nonatomic) UINavigationController *iPadNavController;
@property (strong, atomic) MobileDriveModel *model;

-(void)switchChanged:(UISwitch *)sender;
-(void)pathButtonPressed:(UIButton *)sender;
-(void)popToViewWithDepth:(NSInteger)depth Anamated:(BOOL)animate WithMessage:(NSString *)message;

@end