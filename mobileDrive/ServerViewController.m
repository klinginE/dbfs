//
//  ServerViewController.m
//  mobileDrive
//
//  Created by Sebastian Sanchez on 3/12/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "ServerViewController.h"

// Used to get IP
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "CGDWebServer/GCDWebServer.h"

@interface ServerViewController ()

@end

@implementation ServerViewController{
    GCDWebServer* webServer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    GCDWebServer* webServer = [[GCDWebServer alloc] init];
	// Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) turnOnServer{
    @autoreleasepool {
        // Add a handler to respond to requests on any URL
        [webServer addDefaultHandlerForMethod:@"GET"
                                 requestClass:[GCDWebServerRequest class]
                                 processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                     
                                     return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
                                     
                                 }];
        
        // Use convenience method that runs server on port 8080 until SIGINT received
        [webServer runWithPort:8080];
    }
    NSLog(@"End of turnOnServer");
}

-(void) turnOffServer{
    [webServer stop];
}

// Get IP Address
// Source: http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}
@end
