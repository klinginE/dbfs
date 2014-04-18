//
//  ServerViewController.h
//  mobileDrive
//
//  Created by Sebastian Sanchez on 3/12/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ServerViewController : UIViewController
@property (nonatomic, strong) NSMutableString *current_ip_address;
-(void) turnOnServer;
-(void) turnOffServer;
- (NSString *)getIPAddress;
@end
