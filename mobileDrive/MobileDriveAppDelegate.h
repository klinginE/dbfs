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
#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>

#define PUBLIC_EXT @".pub"
#define PRIVATE_EXT @".pri"

typedef enum {ADD_MODEL_TAG=128, DELETE_MODEL_TAG, MOVE_MODEL_TAG, RENAME_MODEL_TAG} modelUpdateTag;

@class IPadTableViewController;
@interface MobileDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (atomic) BOOL isConnected;
@property (strong, nonatomic) UINavigationController *iPadNavController;
@property (strong, atomic) ServerViewController *serverController;
@property (strong, atomic) MobileDriveModel *model;
@property (nonatomic, retain) AVAudioPlayer * audioPlayer;

-(void)switchChanged:(UISwitch *)sender;
-(void)pathButtonPressed:(UIButton *)sender;
-(void)popToViewWithDepth:(NSInteger)depth Anamated:(BOOL)animate WithMessage:(NSString *)message;
-(void)refreshIpadForTag:(modelUpdateTag)tag From:(NSString *) oldPath To:(NSString *) newPath;
-(BOOL) isValidExtension: (NSString*) listExtensions findFileType:(NSString*)fileExtension;
@end