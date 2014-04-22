//
//  ServerViewController.m
//  mobileDrive
//
//  Created by Sebastian Sanchez on 3/12/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "ServerViewController.h"
#import "MobileDriveAppDelegate.h"
// Used to get IP
#import <ifaddrs.h>
#import <arpa/inet.h>


#define kTrialMaxUploads 50


@interface ServerViewController ()
@end

@implementation ServerViewController{
    __block GCDWebServer* webServer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id) init{
    NSLog(@"viewDidLoad ServerViewController.m");
    _current_ip_address = [NSMutableString stringWithString: @"test"];
    
    @autoreleasepool {
        // Create server
         webServer = [[GCDWebServer alloc] init];

        // Get the path to the website directory
        NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
        
        [webServer addGETHandlerForBasePath:@"/" directoryPath:websitePath indexFilename:nil cacheAge:3600 allowRangeRequests:YES];

        // Redirect root website to index.html
        [webServer addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
            
        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/directory.json" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            NSString * pathArg = [request.query objectForKey:@"path"];
            if ( pathArg == NULL){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }else{
                
                MobileDriveModel *model = [((MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate) model];
//                NSData * json_in_NSData =[[model getJsonContentsIn: pathArg ] dataUsingEncoding:NSUTF8StringEncoding];
                NSData * json_in_NSData =[model getJsonContentsIn: pathArg];
                return [GCDWebServerDataResponse responseWithData: json_in_NSData contentType: @"application/json"];
            }
        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/createDir.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            // Called from GCD thread
            NSString * pathArg = [request.query objectForKey:@"path"];
            if ( pathArg == NULL){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }else{
                NSMutableString* content = [[NSMutableString alloc] init];
                if ( ![[(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model] createDirectory:pathArg] ){
                                [content appendFormat:@"<html><body><p>Folder %@ was created.</p></body></html>",
                                  pathArg
                                ];
                    NSLog(@"Server added to model");
                    // Calling Refresh Function
                    [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: ADD_MODEL_TAG
                                                                                                       From: pathArg To: nil];
                    
                }else{
                    [content appendFormat:@"<html><body><p>Folder %@ was not created.</p></body></html>",
                     pathArg];
                }
                return [GCDWebServerDataResponse responseWithHTML:content];
            }
        }];

        [webServer addHandlerForMethod:@"GET" path:@"/rename.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {

            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];

            // Called from GCD thread
            NSString * oldPath = [request.query objectForKey:@"old"];
            NSString * newPath = [request.query objectForKey:@"new"];
            
            if ( oldPath == NULL || newPath == NULL ){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }
            NSMutableString* content = [[NSMutableString alloc] init];

            int dbResponse = 0;
            if ([oldPath hasSuffix:@"/"]) {
                dbResponse = [model renameDirectory:oldPath to:newPath];
            } else {
                dbResponse = [model renameFile:oldPath to:newPath];
            }

            if (dbResponse == DBFS_OKAY){
                [content appendFormat:@"<html><body><p>Path %@ was renamed to %@.</p></body></html>", oldPath, newPath];
                    
                // Calling Refresh Function
                [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: RENAME_MODEL_TAG
                                                                                                       From: oldPath To: newPath];
            } else {
                [content appendFormat:@"<html><body><p>Path %@ was NOT renamed to %@.</p></body></html>", oldPath, newPath];
            }

            return [GCDWebServerDataResponse responseWithHTML:content];

        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/move.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];
            
            // Called from GCD thread
            NSString * oldPath = [request.query objectForKey:@"old"];
            NSString * newPath = [request.query objectForKey:@"new"];
            
            if ( oldPath == NULL || newPath == NULL ){
                return [GCDWebServerResponse responseWithStatusCode:403];
            }
            NSMutableString* content = [[NSMutableString alloc] init];
            
            int dbResponse = 0;
            if ([oldPath hasSuffix:@"/"]) {
                dbResponse = [model moveDirectory:oldPath to:newPath];
            } else {
                dbResponse = [model moveFile:oldPath to:newPath];
            }
            
            if (dbResponse == DBFS_OKAY){
                [content appendFormat:@"<html><body><p>Path %@ was moved to %@.</p></body></html>", oldPath, newPath];
                
                // Calling Refresh Function
                [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: MOVE_MODEL_TAG
                                                                                                   From: oldPath To: newPath];
            } else {
                [content appendFormat:@"<html><body><p>Path %@ was NOT moved to %@.</p></body></html>", oldPath, newPath];
            }
            
            return [GCDWebServerDataResponse responseWithHTML:content];
            
        }];

        [webServer addHandlerForMethod:@"POST" path:@"/upload.html" requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest * request) {
            GCDWebServerMultiPartFormRequest *mpReq = (GCDWebServerMultiPartFormRequest *)request;
            GCDWebServerMultiPartFile *file = [mpReq.files objectForKey:@"upload-file"];
            NSString *uploadDir = [[mpReq.arguments objectForKey:@"upload-dir"] string];
            NSString *fileName = [file fileName];
            NSString *filePath = [NSString stringWithFormat:@"%@%@", uploadDir, fileName];

            NSData * tempData = [[NSFileManager defaultManager] contentsAtPath: [file temporaryPath]];

            // If temp file wasn't uploaded, respond with error JSON
            if (tempData == nil) {
                NSString *response = @"{\n\t\"type\": \"error\",\n\t\"msg\": \"Upload failed\"\n}";
                return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
            }

            // Overwrite/put file
            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];
            NSDictionary *contents = [model getDirectoryListIn:uploadDir];
            if ([contents objectForKey:fileName]) {
                [model overwriteFile_NSDATA:filePath BLOB:tempData];
            } else {
                [model putFile_NSDATA: filePath BLOB:tempData];
            }

            // Refresh the iPad view
            [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: ADD_MODEL_TAG
                                                                                        From: filePath To: nil];
            // Respond with success JSON
            NSString *response = @"{\n\t\"type\": \"success\",\n\t\"msg\": \"Upload succeeded\"\n}";
            return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/seeImage.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {


            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];
            
            NSString *path = [request.query objectForKey:@"path"];
            NSData * tempData;
            
            NSString * fileExtension = [ [path lastPathComponent] pathExtension];
            
            NSString * imageExtensions =  [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate imageExtensions];
            
            BOOL validExt = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate isValidExtension:imageExtensions
                                                                                                      findFileType:fileExtension];

            if (!validExt) {
                return [GCDWebServerDataResponse responseWithHTML:@"<html><body>File type is not allowed to be viewed.</body></html>"];
            }
            
            tempData = [model getFile_NSDATA:path];
            if ( tempData == nil) {
                return [GCDWebServerDataResponse responseWithHTML:@"<html><body>Failed to get file from DB.</body></html>"];
            }
            
            NSString * contentTypeString = [NSString stringWithFormat:@"image/%@", fileExtension];
            GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:tempData contentType:contentTypeString];
            return response;
        }];
        
        [webServer addHandlerForMethod:@"GET" path:@"/download.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            
            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];
                        NSString *path = [request.query objectForKey:@"path"];
            NSData * tempData;
            tempData = [model getFile_NSDATA:path];
            if ( tempData == nil) {
                return [GCDWebServerDataResponse responseWithHTML:@"<html><body>Failed to get file from DB.</body></html>"];
            }
            
            NSString *fnHeader = [NSString stringWithFormat:@"attachment; filename=%@", [path lastPathComponent]];
            GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:tempData contentType:@"application/octet-stream"];
            [response setValue:fnHeader forAdditionalHeader:@"Content-Disposition"];
            return response;
        }];

        [webServer addHandlerForMethod:@"GET" path:@"/delete.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
            NSString *path = [request.query objectForKey:@"path"];
            MobileDriveModel *model = [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate model];

            int dbResponse = 0;

            if ([path hasSuffix:@"/"]) {
                dbResponse = [model deleteDirectory:path];
            } else {
                dbResponse = [model deleteFile:path];
            }

            if (dbResponse != DBFS_OKAY) {
                // Respond with error JSON
                NSString *response = @"{\n\t\"type\": \"error\",\n\t\"msg\": \"Delete failed\"\n}";
                return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
            }

            // Refresh the iPad view
            [(MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate refreshIpadForTag: DELETE_MODEL_TAG
                                                                                               From: path To: nil];

            // Respond with success JSON
            NSString *response = @"{\n\t\"type\": \"success\",\n\t\"msg\": \"Delete succeeded\"\n}";
            return [GCDWebServerDataResponse responseWithData: [response dataUsingEncoding:NSUTF8StringEncoding] contentType: @"application/json"];
        }];

        [webServer start];
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad ServerViewController.m");
    //	webServer = [[GCDWebServer alloc] init];
	// Do any additional setup after loading the view.

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) turnOnServer{
    [webServer start];
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
