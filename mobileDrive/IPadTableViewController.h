//
//  IPadTableViewController.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobileDriveAppDelegate.h"

#define LARGE_FONT_SIZE 30.0
#define MEDIAN_FONT_SIZE 25.0
#define SMALL_FONT_SIZE 20.0
#define CELL_HEIGHT (LARGE_FONT_SIZE + SMALL_FONT_SIZE + 10.0)
#define NUM_ALERTS 5

@interface IPadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

typedef enum {HELP_TAG, ADD_DIR_TAG, BACK_TAG} buttonTag;
typedef enum {ADD_TAG=512, DELETE_TAG, MOVE_TAG, RENAME_TAG, CONFIRM_TAG, NONE} allertTag;

typedef struct {

   char *currentDir;
   char *currentPath;

}state;

//FIXME change the type of fsModel from id to class name of the iPad file system model class.
-(id)initWithState:(state)currentState model:(id)fsModel target:(MobileDriveAppDelegate *)respond switchAction:(SEL)action forEvents:(UIControlEvents)events;
-(void)buttonPressed:(id)sendr;
-(UIBarButtonItem *)makeButtonWithTitle:(NSString *)title
                                    Tag:(NSInteger)tag
                                  Color:(UIColor *)color
                                 Target:(id)target
                                 Action:(SEL)action;

@end