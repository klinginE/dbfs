//
//  MobileDriveAppDelegate.m
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.

#import "MobileDriveAppDelegate.h"
#import "IPadTableViewController.h"
#import <string.h>

@interface MobileDriveAppDelegate()

@property (strong, nonatomic) IPadTableViewController *iPadTableViewController;

@end

@implementation MobileDriveAppDelegate

-(void)switchChanged:(UISwitch *)sender {

    self.isConnected = [sender isOn];
    NSLog(@"switchChanged %d", self.isConnected);
    //FIXME add code to turn on/off server here

}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // intit global app properties
    self.isConnected = YES;

//  intit the model
    self.model = [[MobileDriveModel alloc] init];

    // init root table view controler
    self.iPadTableViewController = [[IPadTableViewController alloc] initWithPath:@"/"
                                                                           target:self
                                                                     switchAction:@selector(switchChanged:)
                                                                        forEvents:UIControlEventValueChanged];
    self.iPadTableViewController.title = @"/";
    UIBarButtonItem *backButton = [self.iPadTableViewController makeButtonWithTitle:@"/"
                                                                           Tag:HELP_TAG
                                                                         Color:nil
                                                                        Target:nil
                                                                        Action:nil];
    [self.iPadTableViewController.navigationItem setBackBarButtonItem:backButton];

    // init nav controller
    UINavigationController *iPadNavController = [[UINavigationController alloc] initWithRootViewController:self.iPadTableViewController];
    iPadNavController.title = @"NavController";
    [iPadNavController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:LARGE_FONT_SIZE],
                                                            NSFontAttributeName,
                                                            nil]];

    // set up window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = iPadNavController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end