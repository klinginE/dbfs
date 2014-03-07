//
//  IPadTableViewController.h
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IPadTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, atomic) NSString *currentDir;

-(id)initWithDir:(NSString *)cd;

@end
