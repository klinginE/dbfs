//
//  AudioPlayerViewController.m
//  mobileDrive
//
//  Created by user on 4/17/14.
//  Copyright (c) 2014 Eric Klinginsmith. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import "MobileDriveAppDelegate.h"

@interface AudioPlayerViewController ()
@property (weak, atomic) MobileDriveAppDelegate *appDelegate;
@end

@implementation AudioPlayerViewController

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
    _appDelegate = (MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidDisappear:(BOOL)animated{
    if( self.appDelegate.audioPlayer ){
        [self.appDelegate.audioPlayer stop];
        self.appDelegate.audioPlayer = nil;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
