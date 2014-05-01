//
//  MobileDriveAppDelegate.m
//  mobileDrive
//
//  Created by Eric Klinginsmith on 3/6/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.

#import <string.h>
#import "MobileDriveAppDelegate.h"
#import "ServerViewController.h"
#import "IPadTableViewController.h"
#import "CGDWebServer/GCDWebServer.h"


@interface MobileDriveAppDelegate() <IPadTableViewControllerDelegate>

@property (strong, nonatomic) IPadTableViewController *iPadTableViewController;

@end

@implementation MobileDriveAppDelegate{
    NSString *ipAddress;
    NSString *port;
}

-(void)switchChanged:(UISwitch *)sender {

    BOOL switchState = [sender isOn];
    if (self.isConnected != switchState)
        self.isConnected = switchState;
    else
        return;

    //NSLog(@"switchChanged %d", self.isConnected);
    if(self.isConnected){
        [self.serverController turnOnServer];
    }else{
        [self.serverController turnOffServer];
    }

    //FIXME add code to turn on/off server here
}

-(void)pathButtonPressed:(UIButton *)sender {

    assert(sender.tag >= 0);
    assert([self.iPadNavController.viewControllers count] - 1 >= sender.tag);
    [self.iPadNavController popToViewController:[self.iPadNavController.viewControllers objectAtIndex:sender.tag]
                                       animated:YES];

}

-(void)refreshIpadForTag:(modelUpdateTag)tag From:(NSString *)oldPath To:(NSString *)newPath {

//    NSLog(@"Tag: %u", tag);
//    NSLog(oldPath);
//    NSLog(newPath);

    NSNumber *n = [[NSNumber alloc] initWithInt:tag];
    NSArray *a = [[NSArray alloc] initWithObjects:n, oldPath, newPath, nil];
    IPadTableViewController *topController = ((IPadTableViewController *)self.iPadNavController.topViewController);
    
    if (tag != RENAME_MODEL_TAG)
        [topController performSelectorOnMainThread:@selector(refreshWithArray:) withObject:a waitUntilDone:YES];
    else {

        NSInteger d = topController.iPadState.depth;
        for (; d >= 0; d--)
            [self.iPadNavController.viewControllers[d] performSelectorOnMainThread:@selector(refreshWithArray:) withObject:a waitUntilDone:YES];

    }

}

-(void)popToViewWithDepth:(NSInteger)depth Anamated:(BOOL)animate WithMessage:(NSString *)message {

    assert(depth >= 0);
    assert([self.iPadNavController.viewControllers count] - 1 >= depth);

    [self.iPadNavController popToViewController:self.iPadNavController.viewControllers[depth] animated:animate];

    if (message) {

        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle:@"Had to redirect to new directory because:"];
        [alert setMessage:message];
        [alert addButtonWithTitle:@"OK"];
        [alert show];

    }

}

-(void)changeAddressIP:(NSString *)ip Port:(NSString *)portNum {

    ipAddress = ip;
    port = portNum;
    for (UIViewController *vc in [self.iPadNavController viewControllers])
        if ([vc isMemberOfClass:[IPadTableViewController class]]) {

            IPadTableViewController *viewContrller = (IPadTableViewController *)vc;
            [viewContrller setIPAdress:ip WithPort:portNum];

        }

}

-(void)rebuildStackWithPath:(NSString *)path {

    [self.iPadNavController popToRootViewControllerAnimated:NO];
    NSString *currentPath = @"/";
    NSInteger len = [[path pathComponents] count] - 1;
    for (int i = 1; i < len; i++) {

        currentPath = [NSString stringWithFormat:@"%@%@/", currentPath, [path pathComponents][i]];
        IPadTableViewController *temp = [self.iPadTableViewController makeSubControllerForPath:currentPath];
        [temp.view setNeedsDisplay];
        [self.iPadNavController pushViewController:temp animated:NO];

    }

}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    _imageExtensions = @"jpg jpeg gif png bmp tiff tif bmpf ico cur xbm tga";
    _docExtensions = @"pdf doc docx xlsx xls ppt pptx txt";
    _audioExtensions = @"mp3 m4a wav";


    self.isConnected = YES;
    self.model = [[MobileDriveModel alloc] init];
    self.serverController = [[ServerViewController alloc] init];
    

    ipAddress = [self.serverController getIPAddress];
    port = [NSString stringWithFormat:@"%d", (NSInteger)kDefaultPort];

    // init root table view controler
    self.iPadTableViewController = [[IPadTableViewController alloc] initWithPath:@"/"
                                                                        ipAddress:ipAddress
                                                                            port:port
                                                                    switchAction:@selector(switchChanged:)
                                                                       forEvents:UIControlEventValueChanged
                                                                      pathAction:@selector(pathButtonPressed:)
                                                                      pathEvents:UIControlEventTouchUpInside];

    // init nav controller
    _iPadNavController = [[UINavigationController alloc] initWithRootViewController:self.iPadTableViewController];
    [_iPadNavController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:LARGE_FONT_SIZE],
                                                            NSFontAttributeName,
                                                            nil]];

    // set up window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = _iPadNavController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;

}

-(void)applicationWillResignActive:(UIApplication *)application {
    [self.serverController turnOffServer];
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [self.serverController turnOffServer];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.serverController turnOnServer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.serverController turnOnServer];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(BOOL) isValidExtension: (NSString*) listExtensions findFileType:(NSString*)fileExtension {
    
    fileExtension = [fileExtension lowercaseString];
    
    NSArray *singleImageExtensions = [listExtensions componentsSeparatedByString: @" "];
    
    // Looking to see if file is an image
    for (NSString *ext in singleImageExtensions)
        if ([fileExtension isEqualToString:ext])
            return YES;
    
    return NO;
    
}

@end