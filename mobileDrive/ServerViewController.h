//
//  ServerViewController.h
//  mobileDrive
//
//  Created by Sebastian Sanchez on 3/12/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServerViewController : UIViewController

-(void) turnOnServer;
-(void) turnOffServer;
- (NSString *)getIPAddress;
@end
