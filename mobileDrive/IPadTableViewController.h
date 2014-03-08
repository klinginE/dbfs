//
//  IPadTableViewController.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IPadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

typedef enum {HELP_TAG, ADD_DIR_TAG} buttonTag;

@property (weak, atomic) NSString *currentDir;

-(id)initWithDir:(NSString *)cd;
-(void)buttonPressed:(id)sendr;

@end
