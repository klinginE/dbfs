//
//  IPadTableViewController.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

// Imports
#import <UIKit/UIKit.h>
#import "MobileDriveAppDelegate.h"
#import "IPadState.h"

// Defines
#define LARGE_FONT_SIZE 30.0
#define MEDIAN_FONT_SIZE 25.0
#define SMALL_FONT_SIZE 20.0
#define CELL_HEIGHT (LARGE_FONT_SIZE + SMALL_FONT_SIZE + 10.0)
#define NUM_ALERTS 6
#define PATH_VIEW_HEIGHT (MEDIAN_FONT_SIZE * 3)
#define IP_TAG 512

// Enums
typedef enum {HELP_BUTTON_TAG, ADD_DIR_BUTTON_TAG, BACK_BUTTON_TAG, MOVE_BUTTON_TAG, RENAME_BUTTON_TAG, DELETE_BUTTON_TAG, CANCEL_BUTTON_TAG} buttonTag;
typedef enum {ADD_ALERT_TAG=512, DELETE_ALERT_TAG, MOVE_ALERT_TAG, RENAME_ALERT_TAG, CONFIRM_ALERT_TAG, ERROR_ALERT_TAG, NONE} alertTag;

// For checking file extensions
enum{
    IMAGE_EXTENSION = 0x01,
    PDF_EXTENSION = 0x02,
    AUDIO_EXTENSION = 0x04,
    UNKNOWN_EXTENSION = 0x08,
    DOC_EXTENSION = 0x10,
    GENERAL_EXTENSION = 0x20
};


// Protocol
@protocol IPadTableViewControllerDelegate <NSObject, UIDocumentInteractionControllerDelegate>

@required
@property (atomic) BOOL isConnected;
@property (strong, atomic) MobileDriveModel *model;

-(void)switchChanged:(UISwitch *)sender;
-(void)pathButtonPressed:(UIButton *)sender;
-(void)refreshIpadForTag:(modelUpdateTag)tag From:(NSString *)oldPath To:(NSString *)newPath;
-(void)popToViewWithDepth:(NSInteger)depth Anamated:(BOOL)animate WithMessage:(NSString *)message;

@end

@interface IPadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIDocumentInteractionControllerDelegate>

// Properties
@property (strong, atomic) IPadState *iPadState;

// Methods
// Public inits
-(id)initWithPath:(NSString *)currentPath
        ipAddress:(NSString *)ip
             port:(NSString *)port
     switchAction:(SEL)sAction
        forEvents:(UIControlEvents)sEvents
       pathAction:(SEL)pAction
       pathEvents:(UIControlEvents)pEvents;

// Public allocs
-(UIBarButtonItem *)makeBarButtonWithTitle:(NSString *)title
                                       Tag:(NSInteger)tag
                                    Target:(id)target
                                    Action:(SEL)action;
-(UIButton *)makeButtonWithTitle:(NSString *)title
                             Tag:(NSInteger)tag
                          Target:(id)target
                          Action:(SEL)action
                       ForEvents:(UIControlEvents)events;

// Public dealloc
-(void)dealloc;

// Public setter
-(void)setIPAdress:(NSString *)ip WithPort:(NSString *)port;

// Public getters
-(NSString *)dirAtDepth:(NSInteger)depth InPath:(NSString *)path;
-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font;
-(UIAlertView *)objectInArray:(NSArray *)a WithTag:(NSInteger)tag;

// Public converter
//-(char *)nsStringToCString:(NSString *)str;

// Events
-(void)refreshWithArray:(NSArray *)a;
-(void)refreshForTag:(modelUpdateTag)tag From:(NSString *)oldPath To:(NSString *)newPath;

@end