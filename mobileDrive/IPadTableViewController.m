//
//  IPadTableViewController.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

// Imports
#import "IPadTableViewController.h"
#import <string.h>
#import <assert.h>
#import "CODialog.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface IPadTableViewController ()

// Private Properties
// State
@property (weak, atomic) MobileDriveAppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *filesArray;

// Controllers
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (strong, nonatomic) UIImagePickerController *eImagePickerController;
@property (strong, nonatomic) MFMailComposeViewController *mailComposeViewController;

// Views
@property (strong, atomic) NSMutableArray *alertViews;
@property (strong, nonatomic) NSMutableArray *actionSheetButtons;
@property (strong, atomic) UISwitch *conectSwitchView;
@property (strong, nonatomic) UIScrollView *helpScrollView;
@property (strong, nonatomic) UILabel *helpLabelView;
@property (strong, nonatomic) UITableView *mainTableView;
@property (strong, nonatomic) UIScrollView *pathScrollView;
@property (strong, nonatomic) UILabel *pathLabelView;
@property (strong, nonatomic) CODialog *detailView;
@property (strong, nonatomic) UISwitch *extSwitch;
@property (strong, nonatomic) UIBarButtonItem *menuButton;

// Actions
@property (assign) SEL switchAction;
@property (assign) SEL pathAction;

// Events
@property (assign) UIControlEvents switchEvents;
@property (assign) UIControlEvents pathEvents;

// Colors
@property (strong, nonatomic) UIColor *barColor;
@property (strong, nonatomic) UIColor *buttonColor;
@property (strong, nonatomic) UIColor *toolBarColor;

// Private Initers
-(void)initAlerts:(NSMutableArray *)alerts;
-(void)initActionSheetButtons:(NSMutableArray *)buttons;
-(void)initPathViewWithAction:(SEL)action ForEvents:(UIControlEvents)events;

// Private Allocs
-(void)makeFrameForViews;
-(void)loadView;

// Private Event Handelers
-(void)viewWillAppear:(BOOL)animated;
-(void)orientationChanged:(NSNotification *)note;
-(BOOL)strOkay:(NSString *)str ForTag:(alertTag)tag IsDir:(BOOL)dir;
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
-(void)buttonPressed:(UIBarButtonItem *)sender;
-(void)detailedVeiwButtonPressed:(UIButton *)sender;
-(void)handleLongPress:(UILongPressGestureRecognizer*)sender;
-(void)reloadTableViewData;
-(void)viewDidLoad;

// Display Views
-(void)displayHelpPage;
-(void)displayAddDirPage;
-(void)displayDetailedViwForItem:(NSDictionary *)dict WithKey:(NSString *)key;

// Table View Data Source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

// Table View Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

// Convenience
-(char)findFileType:(NSString *)fileExtension;

@end

@implementation IPadTableViewController {

    NSDictionary *selectedDict;
    NSString *selectedKey;
    char extensionTypeFound;// used for opening files on iPad

}

#pragma mark - Initers

//===========================================================================
//Inits object to be on the current path with the given ip and port. The next
//two params set up the ip switch and the last
//===========================================================================
-(id)initWithPath:(NSString *)currentPath
        ipAddress:(NSString *)ip
             port:(NSString *)port
     switchAction:(SEL)sAction
        forEvents:(UIControlEvents)sEvents
       pathAction:(SEL)pAction
       pathEvents:(UIControlEvents)pEvents {

    self = [super init];
    if (self) {

        // init State
        _iPadState = [[IPadState alloc] initWithPath:currentPath
                                             Address:ip
                                                Port:port];
        _appDelegate = (MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate;
        self.title = self.iPadState.currentDir;
        selectedDict = nil;
        selectedKey = nil;

        // init Actions
        _switchAction = sAction;
        _pathAction = pAction;

        // init Events
        _switchEvents = sEvents;
        _pathEvents = pEvents;

        // init Colors
        _buttonColor = [UIColor colorWithRed:(0.0/255.0)
                                       green:(0.0/255.0)
                                        blue:(255.0/255.0)
                                       alpha:1.0f];
        _barColor = [UIColor colorWithRed:0.75f
                                    green:0.75f
                                     blue:0.75f
                                    alpha:1.0f];
        _toolBarColor = [UIColor colorWithRed:0.65f
                                        green:0.65f
                                         blue:0.65f
                                        alpha:1.0f];

    }

    return self;

}

//=================================================================
//Creates and stores all global level alerts in the array passed in
//=================================================================
-(void)initAlerts:(NSMutableArray *)alerts {

    //start the alerts id at add alert and loop through all the alerts
    for (int i = ADD_ALERT_TAG; i < (NUM_ALERTS + ADD_ALERT_TAG); i++) {

        UIAlertView *alert = [[UIAlertView alloc] init];
        switch (i) {

            case ADD_ALERT_TAG:
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Add a Directory"];
                [alert setMessage:@"Give it a name:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = ADD_ALERT_TAG;
                break;
            case DELETE_ALERT_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"Deleting a File/Directory"];
                [alert setMessage:@"Are You Sure?"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = DELETE_ALERT_TAG;
                break;
            case MOVE_ALERT_TAG:
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Moving a File/Directory"];
                [alert setMessage:@"Give it a new path:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = MOVE_ALERT_TAG;
                break;
            case RENAME_ALERT_TAG:
            {
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Renaming a File/Directory"];
                [alert setMessage:@"Give it a new name:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];

                // Rename needs a switch for users to be able to add extentions
                UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, SMALL_FONT_SIZE)];
                [subView setBackgroundColor:[UIColor clearColor]];

                UILabel *extLable = [[UILabel alloc] init];
                extLable.text = @"Add extension: ";
                extLable.font = [UIFont systemFontOfSize:VERY_SMALL_FONT_SIZE];
                extLable.frame = CGRectMake(10, -5, [self sizeOfString:extLable.text withFont:extLable.font].width, [self sizeOfString:extLable.text withFont:extLable.font].height);

                _extSwitch = [[UISwitch alloc] init];
                self.extSwitch.transform = CGAffineTransformMakeScale(0.65, 0.65);
                self.extSwitch.frame = CGRectMake(extLable.frame.size.width + extLable.frame.origin.x, -3, self.extSwitch.frame.size.width, self.extSwitch.frame.size.height);
                self.extSwitch.on = YES;
                [self.extSwitch setTintColor:[UIColor grayColor]];

                [subView addSubview:extLable];
                [subView addSubview:self.extSwitch];

                [alert setValue:subView forKey:@"accessoryView"];
                alert.tag = RENAME_ALERT_TAG;

            }// end of rename block
                break;
            case CONFIRM_ALERT_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"Confirm Change"];
                [alert setMessage:@"Are you sure you want to perform this action?"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = CONFIRM_ALERT_TAG;
                break;
            case ERROR_ALERT_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"Error!"];
                [alert setMessage:@""];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = ERROR_ALERT_TAG;
                break;
            case DELETE_ALL_ALERT_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"Deleting all content from Mobile Drive!"];
                [alert setMessage:@"Are you Sure?"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = DELETE_ALL_ALERT_TAG;
                break;
            default:
                break;

        }// end of switch

        [alerts addObject:alert];

    }// end of for

}

//==============================================================================
//Creates and stores all global level detail view buttons in the array passed in
//==============================================================================
-(void)initActionSheetButtons:(NSMutableArray *)buttons {

    [buttons addObject:@"Open"];//remove this line to get rid of opening files
    [buttons addObject:@"Email"];//remove this line to get rid of emailing files
    [buttons addObject:@"Move"];
    [buttons addObject:@"Rename"];
    [buttons addObject:@"Delete"];
    [buttons addObject:@"Cancel"];

}

//===================================================================
//Gets the path view at the top of the iPad screen created and set up
//===================================================================
-(void)initPathViewWithAction:(SEL)action ForEvents:(UIControlEvents)events {

    //cache values
    UIFont *textFont = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];//cache font
    CGSize currentPathSize = [self sizeOfString:self.iPadState.currentPath
                                       withFont:textFont];//cache size
    CGFloat pathY = (PATH_VIEW_HEIGHT - MEDIAN_FONT_SIZE)/ 4.0;//cache y value

    //get label set up
    UILabel *pathLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    pathLabel.text = @"Path: ";
    [pathLabel setFont:self.pathLabelView.font];
    [pathLabel setFrame:CGRectMake(SMALL_FONT_SIZE,
                                   pathY,
                                   [self sizeOfString:pathLabel.text
                                             withFont:textFont].width,
                                   MEDIAN_FONT_SIZE)];
    //cache path lable
    CGSize pathLabelSize = [self sizeOfString:pathLabel.text withFont:textFont];

    //add path lable to pathScrollView
    [self.pathScrollView addSubview:pathLabel];
    self.pathLabelView.text = pathLabel.text.copy;
    [self.pathLabelView setFont:textFont];
    [self.pathLabelView setFrame:CGRectMake(SMALL_FONT_SIZE,
                                            pathY,
                                            currentPathSize.width + pathLabelSize.width,
                                            currentPathSize.height)];

    //add the rest of the path including the root slash
    NSString *title = @" / ";
    NSInteger len = 0;
    for (int i = 1; i <= (self.iPadState.depth + 1); i++) {

        //get dir for depth i - 1
        title = [self dirAtDepth:(i - 1)
                          InPath:self.iPadState.currentPath];

        //if depth is root then set title to have spaces surounding root
        //this makes it easyer for the usr to click on
        if (i == 1 && [title isEqualToString:@"/"])
            title = @"  /  ";

        // make button for current dir at depth i - 1
        UIButton *pathButton = [self makeButtonWithTitle:title
                                                     Tag:(i - 1)
                                                  Target:self.appDelegate
                                                  Action:action
                                               ForEvents:events];
        CGSize titleSize = [self sizeOfString:title
                                     withFont:pathButton.titleLabel.font];
        pathButton.frame = CGRectMake(self.view.frame.origin.x + SMALL_FONT_SIZE + pathLabelSize.width + len,
                                      pathY,
                                      titleSize.width,
                                      MEDIAN_FONT_SIZE);
        pathButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

        // if dir is final dir then color it gray and disable button
        if (i == (self.iPadState.depth + 1)) {

            [pathButton setEnabled:NO];
            [pathButton setTitleColor:[UIColor darkGrayColor]
                             forState:UIControlStateNormal];

        }
        len += titleSize.width;
        [self.pathScrollView addSubview:pathButton];
        self.pathLabelView.text = [NSString stringWithFormat:@"%@%@",
                                   self.pathLabelView.text,
                                   pathButton.titleLabel.text];

    }// end of for

}

#pragma mark - Allocs

-(UIBarButtonItem *)makeBarButtonWithTitle:(NSString *)title
                                       Tag:(NSInteger)tag
                                    Target:(id)target
                                    Action:(SEL)action {

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title
                                                               style:UIBarButtonItemStyleBordered
                                                              target:target
                                                              action:action];
    [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:MEDIAN_FONT_SIZE],
                                    NSFontAttributeName,
                                    nil]
                          forState:UIControlStateNormal];
    button.tag = tag;
    button.tintColor = self.buttonColor;

    return button;

}

-(UIButton *)makeButtonWithTitle:(NSString *)title
                             Tag:(NSInteger)tag
                          Target:(id)target
                          Action:(SEL)action
                       ForEvents:(UIControlEvents)events {

    UIButton *button = [[UIButton alloc] init];
    [button addTarget:target
               action:action
     forControlEvents:events];
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:MEDIAN_FONT_SIZE]];
    button.tag = tag;
    [button setTitleColor:self.buttonColor forState:UIControlStateNormal];

    return button;

}

-(void)makeFrameForViews {

    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    CGFloat mainScreenWidth = mainScreenBounds.size.width;
    CGFloat mainScreenHeight = mainScreenBounds.size.height;

    if([self interfaceOrientation] == UIInterfaceOrientationLandscapeLeft ||
       [self interfaceOrientation] == UIInterfaceOrientationLandscapeRight) {

        CGFloat temp = mainScreenWidth;
        mainScreenWidth = mainScreenHeight;
        mainScreenHeight = temp;

    }

    if (self.view)
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y,
                                     mainScreenWidth,
                                     mainScreenHeight - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height - self.navigationController.toolbar.frame.size.height);

    if (self.pathLabelView) {

        CGSize pathTextSize = [self sizeOfString:self.pathLabelView.text withFont:self.pathLabelView.font];
        self.pathLabelView.frame = CGRectMake(self.pathLabelView.frame.origin.x,
                                              self.pathLabelView.frame.origin.y,
                                              pathTextSize.width,
                                              pathTextSize.height);

    }

    if (self.pathScrollView && self.pathLabelView) {

        CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
        CGFloat statusBarOffset = 20.0;
        if (statusRect.size.height <= statusRect.size.width)
            statusBarOffset = statusRect.size.height;
        else
            statusBarOffset = statusRect.size.width;
        
        self.pathScrollView.frame = CGRectMake(self.view.frame.origin.x,
                                               statusBarOffset + self.navigationController.navigationBar.frame.size.height,
                                               //statusRect.origin.y + statusRect.size.height + self.navigationController.navigationBar.frame.size.height,
                                               mainScreenWidth,
                                               PATH_VIEW_HEIGHT);
        self.pathScrollView.contentSize = CGSizeMake(self.pathLabelView.frame.size.width + (SMALL_FONT_SIZE * 2),
                                                     self.pathLabelView.frame.size.height);

    }

    if (self.mainTableView)
        self.mainTableView.frame = CGRectMake(0,
                                              self.pathScrollView.frame.origin.y + self.pathScrollView.frame.size.height,
                                              mainScreenWidth,
                                              mainScreenHeight - self.pathScrollView.frame.origin.y - PATH_VIEW_HEIGHT - self.navigationController.toolbar.frame.size.height);
    if (self.helpLabelView) {

        CGSize textSize = [self sizeOfString:self.helpLabelView.text withFont:self.helpLabelView.font];
        self.helpLabelView.frame = CGRectMake(LARGE_FONT_SIZE,
                                         self.view.frame.origin.y,
                                         textSize.width + LARGE_FONT_SIZE * 2,
                                         textSize.height + LARGE_FONT_SIZE);

    }

    if (self.helpScrollView && self.helpLabelView) {

        self.helpScrollView.frame = CGRectMake(self.view.frame.origin.x,
                                               self.view.frame.origin.y,
                                               self.view.frame.size.width,
                                               mainScreenHeight);
        self.helpScrollView.contentSize = CGSizeMake(self.helpLabelView.frame.size.width,
                                                     self.helpLabelView.frame.size.height);

    }

}

-(void)loadView {

    //NSLog(@"LoadViews");
    _alertViews = [[NSMutableArray alloc] init];
    [self initAlerts:_alertViews];

    _actionSheetButtons = [[NSMutableArray alloc] init];
    [self initActionSheetButtons:_actionSheetButtons];

    _conectSwitchView = [[UISwitch alloc] init];
    [_conectSwitchView addTarget:self.appDelegate
                          action:self.switchAction
                forControlEvents:self.switchEvents];
    if (self.appDelegate.isConnected)
        _conectSwitchView.on = YES;
    else
        _conectSwitchView.on = NO;

    _helpLabelView = [[UILabel alloc] initWithFrame:CGRectZero];
    _helpLabelView.backgroundColor = [UIColor clearColor];
    _helpLabelView.textColor = [UIColor blackColor];
    _helpLabelView.text = @"";
    _helpLabelView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    _helpLabelView.numberOfLines = 0;
    [_helpLabelView sizeToFit];

    _helpScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [_helpScrollView setBackgroundColor:[UIColor clearColor]];
    [_helpScrollView addSubview:_helpLabelView];
    [_helpScrollView setScrollEnabled:YES];
    [_helpScrollView setBounces:NO];

    _mainTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];
    _mainTableView.dataSource = self;
    _mainTableView.delegate = self;
    self.tableView = _mainTableView;

    self.pathScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.pathScrollView setBackgroundColor:self.barColor];
    [self.pathScrollView setBounces:NO];
    [self.pathScrollView setScrollEnabled:YES];
    self.automaticallyAdjustsScrollViewInsets = NO;

    _pathLabelView = [[UILabel alloc] initWithFrame:CGRectZero];
    _pathLabelView.text = @"";
    _pathLabelView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    _pathLabelView.numberOfLines = 1;
    [self initPathViewWithAction:self.pathAction ForEvents:self.pathEvents];

    // Set up back button
    [self.navigationItem setBackBarButtonItem:[self makeBarButtonWithTitle:@"Back"
                                                                       Tag:BACK_BUTTON_TAG
                                                                    Target:self
                                                                    Action:@selector(buttonPressed:)]];

    self.view = [[UIView alloc] initWithFrame:CGRectZero];

    [self makeFrameForViews];
    [self.view addSubview:self.pathScrollView];
    [self.view addSubview:self.mainTableView];

}

#pragma mark - Deallocs

-(void)dealloc {

    //NSLog(@"dealloc");
    // Free state
    self.iPadState = nil;
    self.filesArray = nil;

    // Free controllers
    self.documentInteractionController = nil;
    self.eImagePickerController = nil;
    self.mailComposeViewController = nil;

    // Free Views
    self.alertViews = nil;
    self.actionSheetButtons = nil;
    self.conectSwitchView = nil;
    self.helpScrollView = nil;
    self.helpLabelView = nil;
    self.mainTableView = nil;
    self.pathLabelView = nil;
    self.pathScrollView = nil;
    self.detailView = nil;
    self.extSwitch = nil;
    self.menuButton = nil;

    // Free Colors
    self.barColor = nil;
    self.buttonColor = nil;
    self.toolBarColor = nil;

    // Dicts
    selectedDict = nil;
    selectedKey = nil;

}

#pragma mark - Setters

-(void)setIPAdress:(NSString *)ip WithPort:(NSString *)port{

    NSString *s = self.iPadState.currentPath;
    _iPadState = nil;
    _iPadState = [[IPadState alloc] initWithPath:s Address:ip Port:port];

    for (UIViewController *vc in [self.navigationController viewControllers])
        for (UIBarButtonItem *bi in vc.toolbarItems)
            if (bi.tag == IP_TAG) {

                UILabel *newLabel = [[UILabel alloc] init];
                newLabel.text = [NSString stringWithFormat:@"IP: http://%@:%@", ip, port];
                newLabel.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
                newLabel.frame = CGRectMake(0,
                                            0,
                                            [self sizeOfString:newLabel.text
                                                      withFont:newLabel.font].width,
                                            MEDIAN_FONT_SIZE);
                bi.customView = newLabel;
                break;

            }

}

#pragma mark - Getters

-(NSString *)dirAtDepth:(NSInteger)depth InPath:(NSString *)path {

    NSString *dir = @"/";
    NSInteger count = -1;
    NSInteger len = [path length];
    int right = 0;
    for (; right < len; right++) {

        if ([path characterAtIndex:right] == '/')
            count++;

        if (count == depth) {

            int left = right;
            for (; left > 0; left--)
                if ([path characterAtIndex:(left - 1)] == '/')
                    break;

            NSRange range;
            range.location = left;
            range.length = ((right + 1) - left);
            dir = [path substringWithRange:range];
            break;

        }

    }

    return dir;

}

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font {

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size];

}

-(UIAlertView *)objectInArray:(NSArray *)a WithTag:(NSInteger)tag {

    for (UIAlertView *object in a)
        if(object.tag == tag)
            return object;

    return nil;

}

#pragma mark - Event Handelers

-(void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    self.conectSwitchView.on = self.appDelegate.isConnected;
    [self makeFrameForViews];
    if (self.filesArray && self.mainTableView)
        [self reloadTableViewData];

}

-(void)orientationChanged:(NSNotification *)note {

    [self makeFrameForViews];

}

-(BOOL)strOkay:(NSString *)str ForTag:(alertTag)tag IsDir:(BOOL)dir {

    NSInteger len = 0;
    if (str)
        len = [str length];
    BOOL passed = NO;
    switch (tag) {

        case DELETE_ALERT_TAG:
        case RENAME_ALERT_TAG:
            if (dir) {
                if (str && len > 1 && [str characterAtIndex:(len - 1)] == '/') {
                    passed = YES;
                    for (int i = 0; i < (len - 1); i++)
                        if ([str characterAtIndex:i] == '/')
                            passed = NO;
                }
            }
            else {
                if (str && len) {
                    passed = YES;
                    for (int i = 0; i < len; i++)
                        if ([str characterAtIndex:i] == '/')
                            passed = NO;
                }
            }
            break;
        case ADD_ALERT_TAG:
        case MOVE_ALERT_TAG:
            if (dir) {
                if (str && len > 1 && [str characterAtIndex:(len - 1)] == '/')
                    passed = YES;
            }
            else {
                if (str && len)
                    passed = YES;
            }
            break;
        default:
            passed = NO;
            break;

    }
    return passed;

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != 0) {

        static NSString *text = @"";
        static alertTag previousTag = NONE;

        switch (alertView.tag) {

            case ADD_ALERT_TAG:
                previousTag = ADD_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                if (text && [text length])
                    [[self objectInArray:self.alertViews WithTag:CONFIRM_ALERT_TAG] show];
                else {

                    UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                    [alert setMessage:@"You must provide a name."];
                    [alert show];

                }
                break;
            case DELETE_ALERT_TAG:
                if (selectedDict && selectedKey) {

                    NSString *path = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, selectedKey];
                    BOOL isDir = [[selectedDict objectForKey:@"type"] boolValue];

                    if ([self strOkay:selectedKey ForTag:DELETE_ALERT_TAG IsDir:isDir]) {

                        DBFS_Error err = DBFS_OKAY;
                        if (isDir)
                            err = [self.appDelegate.model deleteDirectory:path];
                        else
                            err = [self.appDelegate.model deleteFile:path];
                        if (err == DBFS_OKAY)
                            [self reloadTableViewData];
                        else {

                            NSLog(@"DBFS Not OK with DELETE");
                            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                            [alert setMessage:[self.appDelegate.model dbError:err]];
                            [alert show];

                        }

                    }
                    else {

                        UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                        [alert setMessage:@"Name invalid: Name cannot contain '/'"];
                        [alert show];

                    }

                    selectedDict = nil;
                    selectedKey = nil;

                }
                else {

                    NSLog(@"Fatal error in alertView:clickedButtonAtIndex:, selectedDict or selectedKey are NULL.");
                    abort();

                }
                break;
            case MOVE_ALERT_TAG:
                previousTag = MOVE_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                if (text && [text length])
                    [[self objectInArray:self.alertViews WithTag:CONFIRM_ALERT_TAG] show];
                else {
                    
                    UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                    [alert setMessage:@"You must provide a path."];
                    [alert show];
                    
                }
                break;
            case RENAME_ALERT_TAG:
                previousTag = RENAME_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                if (text && [text length])
                    [[self objectInArray:self.alertViews WithTag:CONFIRM_ALERT_TAG] show];
                else {
                    
                    UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                    [alert setMessage:@"You must provide a name."];
                    [alert show];
                    
                }
                break;
            case CONFIRM_ALERT_TAG:
                switch (previousTag) {

                    case ADD_ALERT_TAG:
                    {

                        NSString *path = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, text];

                        if ([text characterAtIndex:0] != '/')
                            path = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, text];
                        else
                            path = text;
                        if ([path characterAtIndex:([path length] - 1)] != '/')
                            path = [NSString stringWithFormat:@"%@/", path];

                        if ([self strOkay:path ForTag:ADD_ALERT_TAG IsDir:YES]) {

                            DBFS_Error err = [self.appDelegate.model createDirectory:path];
                            if (err == DBFS_OKAY)
                                [self reloadTableViewData];
                            else {

                                NSLog(@"DBFS Not OK with ADD");
                                UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                                [alert setMessage:[self.appDelegate.model dbError:err]];
                                [alert show];

                            }

                        }
                        else {

                            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                            [alert setMessage:@"Name invalid"];
                            [alert show];

                        }
                    }
                        break;
                    case MOVE_ALERT_TAG:
                        if (selectedDict && selectedKey) {

                            NSString *oldPath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, selectedKey];
                            NSString *newPath = text;
                            BOOL isDir = [[selectedDict objectForKey:@"type"] boolValue];

                            // add absoulte path if needed
                            if ([newPath characterAtIndex:0] != '/')
                                newPath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, newPath];

                            // add selectedKey to end if left off
                            NSInteger index = [newPath length] - [selectedKey length];
                            if (index < 0 || ![[newPath substringFromIndex:index] isEqualToString:selectedKey]) {

                                NSString *temp = newPath;
                                if (!isDir) {

                                    NSString *oldext = [oldPath pathExtension];
                                    NSString *newext = [temp pathExtension];
                                    if (oldext && [oldext length] && (!newext || [newext length] <= 0))
                                        temp = [NSString stringWithFormat:@"%@.%@", temp, oldext];

                                    index = [temp length] - [selectedKey length];
                                    if (index >= 0 && [[temp substringFromIndex:index] isEqualToString:selectedKey])
                                        newPath = temp;
                                    else {

                                        if ([newPath characterAtIndex:([newPath length] - 1)] != '/')
                                            newPath = [NSString stringWithFormat:@"%@/", newPath];
                                        newPath = [NSString stringWithFormat:@"%@%@", newPath, selectedKey];

                                    }

                                }
                                else {

                                    if ([temp characterAtIndex:([temp length] - 1)] != '/')
                                        temp = [NSString stringWithFormat:@"%@/", temp];

                                    index = [temp length] - [selectedKey length];
                                    if (index >= 0 && [[temp substringFromIndex:index] isEqualToString:selectedKey])
                                        newPath = temp;
                                    else {

                                        if ([newPath characterAtIndex:([newPath length] - 1)] != '/')
                                            newPath = [NSString stringWithFormat:@"%@/", newPath];
                                        newPath = [NSString stringWithFormat:@"%@%@", newPath, selectedKey];

                                    }

                                }

                            }

                            NSInteger newLen = [newPath length];
                            NSInteger oldLen = [oldPath length];

                            if ([self strOkay:oldPath ForTag:MOVE_ALERT_TAG IsDir:isDir] &&
                                [self strOkay:newPath ForTag:MOVE_ALERT_TAG IsDir:isDir] &&
                                (newLen < oldLen || ![oldPath isEqualToString:[newPath substringToIndex:oldLen]])) {

                                DBFS_Error err = DBFS_OKAY;
                                if (isDir)
                                    err = [self.appDelegate.model moveDirectory:oldPath to:newPath];
                                else
                                    err = [self.appDelegate.model moveFile:oldPath to:newPath];
                                if (err == DBFS_OKAY)
                                    [self reloadTableViewData];
                                else {

                                    NSLog(@"DBFS Not OK with MOVE");
                                    UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                                    [alert setMessage:[self.appDelegate.model dbError:err]];
                                    [alert show];

                                }

                            }
                            else {

                                UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                                [alert setMessage:@"Path invalid."];
                                [alert show];

                            }

                            selectedDict = nil;
                            selectedKey = nil;
                            
                        }
                        else {

                            NSLog(@"Fatal error in alertView:clickedButtonAtIndex:, selectedDict or selectedKey are NULL.");
                            abort();

                        }
                        break;
                    case RENAME_ALERT_TAG:
                        if (selectedDict && selectedKey) {

                            BOOL isDir = [[selectedDict objectForKey:@"type"] boolValue];
                            if (isDir && [text characterAtIndex:([text length] - 1)] != '/')
                                text = [NSString stringWithFormat:@"%@/", text];

                            NSString *oldPath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, selectedKey];
                            NSString *newPath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, text];

                            if (!isDir && self.extSwitch && [self.extSwitch isOn]) {

                                NSString *oldext = [oldPath pathExtension];
                                NSString *newext = [newPath pathExtension];

                                if (oldext && [oldext length] && (!newext || [newext length] <= 0))
                                    newPath = [NSString stringWithFormat:@"%@.%@", newPath, oldext];

                            }

                            if ([self strOkay:selectedKey ForTag:RENAME_ALERT_TAG IsDir:isDir] &&
                                [self strOkay:text ForTag:RENAME_ALERT_TAG IsDir:isDir]) {

                                DBFS_Error err = DBFS_OKAY;
                                if (isDir)
                                    err = [self.appDelegate.model renameDirectory:oldPath to:newPath];
                                else
                                    err = [self.appDelegate.model renameFile:oldPath to:newPath];
                                if (err == DBFS_OKAY)
                                    [self reloadTableViewData];
                                else {

                                    NSLog(@"DBFS Not OK With RENAME");
                                    UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                                    [alert setMessage:[self.appDelegate.model dbError:err]];
                                    [alert show];

                                }

                            }
                            else {

                                UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                                [alert setMessage:@"Name invalid: Name cannot contain '/'"];
                                [alert show];

                            }

                            selectedDict = nil;
                            selectedKey = nil;

                        }
                        else {

                            NSLog(@"Fatal error in alertView:clickedButtonAtIndex:, selectedDict or selectedKey are NULL.");
                            abort();

                        }
                        break;
                    default:
                        break;

                }
                previousTag = CONFIRM_ALERT_TAG;
                break;
            case DELETE_ALL_ALERT_TAG:
                [self.appDelegate.model deleteDatabaseRecreate:YES];
                if (self.detailView && !self.detailView.isHidden)
                    [self.detailView hideAnimated:NO];
                if ([self.iPadState.currentDir isEqualToString:@"/"])
                    [self reloadTableViewData];
                else
                    [self.appDelegate popToViewWithDepth:0 Anamated:NO WithMessage:@"Deleting entire database, navigating back to /."];

                break;
            default:
                previousTag = NONE;
                break;

        }

    }
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
        [alertView textFieldAtIndex:0].text = @"";

}

-(void)displayPhotoPicker {

    self.eImagePickerController = [[UIImagePickerController alloc] init];
    self.eImagePickerController.delegate = self;

    self.eImagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.eImagePickerController.navigationBarHidden = NO;

    [self presentViewController:self.eImagePickerController animated:YES completion:nil];

}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    //extracting image from the picker and saving it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        UIImage *imagePicked = [info objectForKey:UIImagePickerControllerOriginalImage];
        __block NSData *imageData;
        NSURL *imagePath = [info valueForKey:UIImagePickerControllerReferenceURL];
        __block NSString *imageName;
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            ALAssetRepresentation *representation = [myasset defaultRepresentation];
            imageName = [representation filename];
            NSString *extention = [[imageName lastPathComponent] lowercaseString];

            if ([extention isEqualToString:@"png"]) {
                imageData = UIImagePNGRepresentation(imagePicked);
            }else{ // It's assumed to be jpg and jpeg
                imageData = UIImageJPEGRepresentation(imagePicked, 1.0);
            }

            NSString *filePath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, imageName];
            DBFS_Error err = [self.appDelegate.model putFile_NSDATA:filePath BLOB:imageData];
            imageData = nil;

            [self.eImagePickerController dismissViewControllerAnimated:YES completion:^{}];
            self.eImagePickerController = nil;
            if (err != DBFS_OKAY) {

                UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
                [alert setMessage:[self.appDelegate.model dbError:err]];
                [alert show];

            }

        };
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:imagePath
                       resultBlock:resultblock
                      failureBlock:nil];

    }

}
-(void)buttonPressed:(UIBarButtonItem *)sender {

    //NSLog(@"buttonPressed");
    switch (sender.tag) {

        case MENU_BUTTON_TAG:
            [self.menuButton setEnabled:NO];
            [self displayActionSheetViewFrom:sender];
            break;
        default:
            break;

    }

}

-(char)check_list_ext:(NSArray *)extTuple findFileType:(NSString*)fileExtension {

    if (extTuple && [extTuple count] >= 2) {

        NSString* listExtensions = extTuple[0];
        char codeExtension = [ (NSNumber *) extTuple[1] charValue ];
        fileExtension = [fileExtension lowercaseString];

        NSArray *singleImageExtensions = [listExtensions componentsSeparatedByString: @" "];
    
        // Looking to see if file is an image
        for (NSString *ext in singleImageExtensions)
            if ([fileExtension isEqualToString:ext])
                return codeExtension;

    }

    return UNKNOWN_EXTENSION;

}

-(char)findFileType:(NSString *)fileExtension {
    // identifying extension
    char extensionTypeFound_temp = UNKNOWN_EXTENSION;

    //NSString *generalExtensions = @"";

    NSMutableArray *allExtensions = [[NSMutableArray alloc] init];

    [allExtensions addObject: @[self.appDelegate.imageExtensions, [[NSNumber alloc] initWithChar:IMAGE_EXTENSION]] ];
    [allExtensions addObject: @[self.appDelegate.docExtensions, [[NSNumber alloc] initWithChar:DOC_EXTENSION]] ];
    [allExtensions addObject: @[self.appDelegate.audioExtensions, [[NSNumber alloc] initWithChar:AUDIO_EXTENSION]] ];
    //[allExtensions addObject: @[generalExtensions, [[NSNumber alloc] initWithChar:GENERAL_EXTENSION]] ];

    for (NSArray *tempTuple in allExtensions) {

        if (extensionTypeFound_temp & UNKNOWN_EXTENSION)
            extensionTypeFound_temp = [self check_list_ext:tempTuple findFileType:fileExtension];
        else
            break;

    }

    return extensionTypeFound_temp;

}

-(void)displayFileWithfilePath:(NSString *)filePath fileName:(NSString *)filename {

    NSData *blob = [self.appDelegate.model getFile_NSDATA:filePath];
    if (blob) {

        NSString *tempfilename = [NSString stringWithFormat:@"temp.%@", [filename pathExtension]];
        NSString *filePath_t = [NSTemporaryDirectory() stringByAppendingString:tempfilename];
        NSURL *url = [NSURL fileURLWithPath:filePath_t];
        NSError *writeError = nil;
        [blob writeToURL:url options:0 error:&writeError];
        if (writeError) {

            NSLog(@"Error write file to disk to display it");
            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
            [alert setMessage:[NSString stringWithFormat:@"Could not write file: %@", filename]];
            [alert show];
            return;

        }
        blob = nil;
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.documentInteractionController.name = filename;
        [self.documentInteractionController setDelegate:self];

        // Preview File
        [self.documentInteractionController presentPreviewAnimated:YES];

    }
    else {

        UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
        [alert setMessage:[NSString stringWithFormat:@"Could not get file: %@", filename]];
        [alert show];

    }

}

-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    return self;
}

-(void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
//    NSLog(@"End Document viewer");
    self.documentInteractionController = nil;

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    switch (buttonIndex) {

        case 0:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            [self displayHelpPage];
            break;
        case 1:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            [self displayAddDirPage];
            break;
        case 2:
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            [self displayPhotoPicker];
            break;
        case 3:
        {
            [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:DELETE_ALL_ALERT_TAG];
            [alert show];
        }
            break;
        default:
            break;

    }
    [self.menuButton setEnabled:YES];

}

-(void)displayActionSheetViewFrom:(UIBarButtonItem *)button {

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Menu"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Need Help?", @"Add Directory", @"Import Image", @"Delete All Content", nil];
    [sheet showFromBarButtonItem:button animated:YES];
    for (UIView *v in [sheet subviews])
        if ([v isKindOfClass:[UIButton class]])
            if ([((UIButton *)v).titleLabel.text isEqualToString:@"Delete All Content"])
                [((UIButton *)v) setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

}

-(void)displayEmailForAttachmentWithPath:(NSString *)path Name:(NSString *)name {

    self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
    [self.mailComposeViewController setMailComposeDelegate:(id)self];

    // Attach an id to the email
    NSData *myData = [self.appDelegate.model getFile_NSDATA:path];
    if (myData) {

        [self.mailComposeViewController addAttachmentData:myData mimeType:[path pathExtension] fileName:name];

        // Fill out the email body text
        [self.mailComposeViewController setMessageBody:@"" isHTML:NO];
        [self presentViewController:self.mailComposeViewController animated:YES completion:^(void){}];

    }
    else {

        UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
        [alert setMessage:@"Could not get data."];
        [alert show];

    }

}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

    // Notifies users about errors associated with the interface
    switch (result) {

        case MFMailComposeResultCancelled:
            NSLog(@"Result: canceled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Result: saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Result: sent");
            break;
        case MFMailComposeResultFailed:
        {
            NSLog(@"Result: failed");
            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
            alert.message = @"Email failed";
            [alert show];
        }
            break;
        default:
        {
            NSLog(@"Result: not sent");
            UIAlertView *alert = [self objectInArray:self.alertViews WithTag:ERROR_ALERT_TAG];
            alert.message = @"Email failed to send";
            [alert show];
        }
            break;

    }
    [self.mailComposeViewController dismissViewControllerAnimated:YES completion:^(void){}];
    self.mailComposeViewController = nil;

}

-(void)detailedVeiwButtonPressed:(UIButton *)sender {

//    NSLog(@"detailedVeiwButtonPressed");
    [self.detailView hideAnimated:NO];
    self.detailView = nil;

    if (selectedKey == nil || selectedDict == nil) {

        NSLog(@"Fatal error in alertView:clickedButtonAtIndex:, selectedDict or selectedKey are NULL.");
        abort();

    }

    if ([sender.titleLabel.text isEqualToString:@"Open"]) {
        // Display file according to type
        NSString *filePath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, selectedKey];
        if (!(extensionTypeFound & UNKNOWN_EXTENSION))
            [self displayFileWithfilePath:filePath fileName:selectedKey];

    }
    else if ([sender.titleLabel.text isEqualToString:@"Email"]) {

        NSString *filePath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, selectedKey];
        [self displayEmailForAttachmentWithPath:filePath Name:selectedKey];

    }
    else if ([sender.titleLabel.text isEqualToString:@"Move"]) {

        UIAlertView *alert = [self objectInArray:self.alertViews WithTag:MOVE_ALERT_TAG];
        [[alert textFieldAtIndex:0] setPlaceholder:self.iPadState.currentPath];
        [alert show];

    }
    else if ([sender.titleLabel.text isEqualToString:@"Rename"]) {

        UIAlertView *alert = [self objectInArray:self.alertViews WithTag:RENAME_ALERT_TAG];
        [[alert textFieldAtIndex:0] setPlaceholder:selectedKey];
        if ([[selectedDict objectForKey:@"Type"] boolValue]) {

            if (self.extSwitch)
                self.extSwitch.on = NO;
            [self.extSwitch setEnabled:NO];

        }
        else {

            if (self.extSwitch)
                self.extSwitch.on = YES;
            [self.extSwitch setEnabled:YES];

        }
        [alert show];


    }
    else if ([sender.titleLabel.text isEqualToString:@"Delete"])
        [[self objectInArray:self.alertViews WithTag:DELETE_ALERT_TAG] show];

}

-(void)handleLongPress:(UILongPressGestureRecognizer*)sender {

    CGPoint location = [sender locationInView:self.mainTableView];
    NSIndexPath *indexPath = [self.mainTableView indexPathForRowAtPoint:location];
    NSDictionary *dict = [self.filesArray objectAtIndex:indexPath.row];
    NSString *key = [dict objectForKey:@"name"];

    if (sender.state == UIGestureRecognizerStateBegan)
        [self displayDetailedViwForItem:dict WithKey:key];

}

-(void)refreshWithArray:(NSArray *)a {

    assert(a);
    assert([a count] >= 2);
    modelUpdateTag tag = ((NSNumber *)a[0]).intValue;
    NSString *from = a[1];
    NSString *to = nil;
    if ([a count] >= 3)
        to = a[2];
    [self refreshForTag:tag From:from To:to];

}

-(void)reloadTableViewData {

    self.filesArray = [self.appDelegate.model getContentsArrayIn:self.iPadState.currentPath];
    [self.mainTableView reloadData];

}

-(void)refreshForTag:(modelUpdateTag)tag From:(NSString *)oldPath To:(NSString *)newPath {

    assert(oldPath);
    NSInteger oldLen = [oldPath length];
    assert(oldLen >= 2);
    NSInteger newLen = [newPath length];
    NSString *currentPath = self.iPadState.currentPath;
    NSInteger currentLen = [currentPath length];

    NSInteger index = oldLen - 1;
    if ([oldPath characterAtIndex:index] == '/')
        index--;
    for (; index >= 0; index--)
        if ([oldPath characterAtIndex:index] == '/')
            break;
    NSString *serverPath = [oldPath substringToIndex:(index + 1)];
    NSInteger serverLen = [serverPath length];

    NSString *oldName = [oldPath substringFromIndex:(index + 1)];

    NSLog(@"refresh currentPath= %@", currentPath);
    NSLog(@"refresh oldPath= %@", oldPath);
    NSLog(@"refresh oldName= %@", oldName);
    NSLog(@"refresh newPath= %@", newPath);
    NSLog(@"refresh serverPath= %@", serverPath);
    NSLog(@"refresh tag= %u", tag);

    if (self.filesArray && self.mainTableView && serverLen <= currentLen)
        switch (tag) {
            case ADD_MODEL_TAG:
                if ([serverPath isEqualToString:currentPath])
                    [self reloadTableViewData];
                break;
            case MOVE_MODEL_TAG:
            case RENAME_MODEL_TAG:
                if ([serverPath isEqualToString:currentPath]) {

                    if (self.detailView &&
                        !self.detailView.isHidden &&
                        [self.detailView.title length] >= [oldName length] &&
                        [oldName isEqualToString:[self.detailView.title substringFromIndex:([self.detailView.title length] - [oldName length])]]) {
                        [self.detailView hideAnimated:NO];
                        self.detailView = nil;
                    }
                    if ([self.documentInteractionController.name length] >= [oldName length] &&
                        [oldName isEqualToString:[self.documentInteractionController.name substringFromIndex:([self.documentInteractionController.name length] - [oldName length])]] &&
                        self.documentInteractionController) {
                        [self.documentInteractionController dismissPreviewAnimated:YES];
                        self.documentInteractionController = nil;
                    }

                    [self reloadTableViewData];

                }
                else if (oldLen <= currentLen && [oldPath isEqualToString:[currentPath substringToIndex:oldLen]] &&
                         [newPath characterAtIndex:(newLen - 1)] == '/') {

                    if (self.detailView && !self.detailView.isHidden) {
                        [self.detailView hideAnimated:NO];
                        self.detailView = nil;
                    }
                    if (self.documentInteractionController) {
                        [self.documentInteractionController dismissPreviewAnimated:YES];
                        self.documentInteractionController = nil;
                    }
                    if (self.eImagePickerController) {
                        [self.eImagePickerController dismissViewControllerAnimated:YES completion:^(void){}];
                        self.eImagePickerController = nil;
                    }
                    if (self.mailComposeViewController) {
                        [self.mailComposeViewController dismissViewControllerAnimated:YES completion:^(void){}];
                        self.mailComposeViewController = nil;
                    }

                    for (int d = (self.iPadState.depth - 1); d >= 0; d--)
                        [self.navigationController.viewControllers[d] refreshForTag:tag From:oldPath To:newPath];

                    NSString *newIpadPath = newPath;
                    if (oldLen < currentLen)
                        newIpadPath = [NSString stringWithFormat:@"%@%@", newIpadPath, [currentPath substringFromIndex:oldLen]];

                    NSString *newAddress = self.iPadState.ipAddress;
                    NSString *newPort = self.iPadState.port;
                    self.iPadState = nil;
                    _iPadState = [[IPadState alloc] initWithPath:newIpadPath Address:newAddress Port:newPort];
                    if ([oldPath isEqualToString:currentPath])
                        self.title = self.iPadState.currentDir;

                    [self.pathScrollView removeFromSuperview];
                    [self.pathLabelView removeFromSuperview];
                    self.pathScrollView = nil;
                    self.pathLabelView = nil;
                    _pathScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
                    [self.pathScrollView setBackgroundColor:self.barColor];
                    [self.pathScrollView setBounces:NO];
                    [self.pathScrollView setScrollEnabled:YES];
                    self.automaticallyAdjustsScrollViewInsets = NO;
                    
                    _pathLabelView = [[UILabel alloc] initWithFrame:CGRectZero];
                    _pathLabelView.text = @"";
                    _pathLabelView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
                    _pathLabelView.numberOfLines = 1;
                    [self initPathViewWithAction:self.pathAction ForEvents:self.pathEvents];
                    [self makeFrameForViews];
                    [self.view addSubview:self.pathScrollView];

                    [self reloadTableViewData];

                }
                break;
            case DELETE_MODEL_TAG:
                if ([serverPath isEqualToString:currentPath]) {

                    if (self.detailView &&
                        !self.detailView.isHidden &&
                        [self.detailView.title length] >= [oldName length] &&
                        [oldName isEqualToString:[self.detailView.title substringFromIndex:([self.detailView.title length] - [oldName length])]]) {
                        [self.detailView hideAnimated:NO];
                        self.detailView = nil;
                    }
                    if ([self.documentInteractionController.name length] >= [oldName length] &&
                        [oldName isEqualToString:[self.documentInteractionController.name substringFromIndex:([self.documentInteractionController.name length] - [oldName length])]] &&
                        self.documentInteractionController) {
                        [self.documentInteractionController dismissPreviewAnimated:YES];
                        self.documentInteractionController = nil;
                    }

                    [self reloadTableViewData];

                }
                else if (oldLen <= currentLen && [oldPath isEqualToString:[currentPath substringToIndex:oldLen]] &&
                         [oldPath characterAtIndex:(oldLen - 1)] == '/') {

                    if (self.detailView && !self.detailView.isHidden) {
                        [self.detailView hideAnimated:NO];
                        self.detailView = nil;
                    }
                    if (self.documentInteractionController) {
                        [self.documentInteractionController dismissPreviewAnimated:YES];
                        self.documentInteractionController = nil;
                    }
                    if (self.eImagePickerController) {
                        [self.eImagePickerController dismissViewControllerAnimated:YES completion:^(void){}];
                        self.eImagePickerController = nil;
                    }
                    if (self.mailComposeViewController) {
                        [self.mailComposeViewController dismissViewControllerAnimated:YES completion:^(void){}];
                        self.mailComposeViewController = nil;
                    }

                    NSInteger depth = -1;
                    for (int i = 0; i < serverLen; i++)
                        if ([serverPath characterAtIndex:i] == '/')
                            depth++;
                    [self.appDelegate popToViewWithDepth:depth Anamated:NO WithMessage:@"Sub directory of current path was deleted."];

                }
                break;
            default:
                break;
        }

}

-(void)viewDidLoad {

    [super viewDidLoad];

    // Set up self to be observer over a orientation change
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];

    // Set up directory Contents
    if(_filesArray == nil)
        _filesArray = [self.appDelegate.model getContentsArrayIn:self.iPadState.currentPath];

    // Add a help button to the top right
    _menuButton = [self makeBarButtonWithTitle:@"≣"
                                           Tag:MENU_BUTTON_TAG
                                        Target:self
                                        Action:@selector(buttonPressed:)];
    self.navigationItem.rightBarButtonItem = self.menuButton;

    // flexiable space holder
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                           target:nil
                                                                           action:nil];

    UILabel *ipLabel = [[UILabel alloc] init];
    ipLabel.text = [NSString stringWithFormat:@"IP: http://%@:%@", self.iPadState.ipAddress, self.iPadState.port];
    ipLabel.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    ipLabel.frame = CGRectMake(0,
                               0,
                               [self sizeOfString:ipLabel.text withFont:ipLabel.font].width,
                               MEDIAN_FONT_SIZE);
    [ipLabel setBackgroundColor:[UIColor clearColor]];
    UIBarButtonItem *ipButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ipLabel];
    ipButtonItem.tag = IP_TAG;

    // make lable for switch
    NSString *switchString = @"Turn on/off server:";
    UILabel *switchLable = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     [self sizeOfString:switchString
                                                                               withFont:[UIFont systemFontOfSize: MEDIAN_FONT_SIZE]].width,
                                                                     MEDIAN_FONT_SIZE)];
    switchLable.text = switchString;
    switchLable.backgroundColor = [UIColor clearColor];
    switchLable.textColor = [UIColor blackColor];
    switchLable.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    [switchLable setTextAlignment:NSTextAlignmentCenter];
    UIBarButtonItem *switchButtonItem = [[UIBarButtonItem alloc] initWithCustomView:switchLable];

    // add switch to the bottom right
    UIBarButtonItem *cSwitch = [[UIBarButtonItem alloc] initWithCustomView:self.conectSwitchView];

    // put objects in toolbar
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:flex, ipButtonItem, flex, switchButtonItem, fixed, cSwitch, flex, nil];
    self.toolbarItems = toolBarItems;

    // set tool bar settings
    self.navigationController.toolbar.barTintColor = self.toolBarColor;
    [self.navigationController.toolbar setOpaque:YES];

    // set navbar settings
    self.navigationController.navigationBar.barTintColor = self.barColor;
    self.navigationController.navigationBar.tintColor = self.buttonColor;
    [self.navigationController setToolbarHidden:NO animated:YES];

    [self.mainTableView reloadData];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

#pragma mark - Dispaly Views

-(void)displayHelpPage {

    NSString *helpMessagePath = [[NSBundle mainBundle] pathForResource:@"helpPage" ofType:@"txt"];
    NSString *helpMessage = [NSString stringWithContentsOfFile:helpMessagePath encoding:NSUTF8StringEncoding error:NULL];
    self.helpLabelView.text = helpMessage;

    UIViewController *helpController = [[UIViewController alloc] init];
    helpController.title = @"Help Page";

    [helpController.view addSubview:self.helpScrollView];
    [self makeFrameForViews];
    [self.navigationController pushViewController:helpController animated:YES];

}

-(void)displayAddDirPage {

    UIAlertView *addDirAlert = [self objectInArray:self.alertViews WithTag:ADD_ALERT_TAG];
    [[addDirAlert textFieldAtIndex:0] setPlaceholder:@"My Dir"];
    [addDirAlert show];

}

-(void)displayDetailedViwForItem:(NSDictionary *)dict WithKey:(NSString *)key {

    UIScrollView *custom = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [custom setBackgroundColor:[UIColor clearColor]];
    [custom setBounces:NO];

    int i = 0;
    CGFloat maxWidth = 0;
    for (NSString *k in [dict keyEnumerator]) {

        if (((![k isEqualToString:@"modified"]) || ([k isEqualToString:@"modified"] && ![[dict objectForKey:@"type"] boolValue])) &&
            ((![k isEqualToString:@"size"])     || ([k isEqualToString:@"size"] &&     ![[dict objectForKey:@"type"] boolValue]))) {

            UILabel *l = [[UILabel alloc] init];
            if ([k isEqualToString:@"modified"]) {

                NSInteger dateSec = [[dict objectForKey:k] integerValue];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PST"];
                NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:dateSec];
                l.text = [NSString stringWithFormat:@"%@: %@", k, [dateFormatter stringFromDate:date]];

            }
            else if ([k isEqualToString:@"type"]) {

                if ([[dict objectForKey:k] boolValue])
                    l.text = [NSString stringWithFormat:@"%@: Directory", k];
                else
                    l.text = [NSString stringWithFormat:@"%@: File", k];

            }
            else if ([k isEqualToString:@"size"])
                l.text = [NSString stringWithFormat:@"%@: %@ Byte(s)", k, [dict objectForKey:k]];
            else
                l.text = [NSString stringWithFormat:@"%@: %@", k, [dict objectForKey:k]];

            [l setFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]];
            CGFloat width = [self sizeOfString:l.text
                                      withFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]].width;
            l.frame = CGRectMake(0, SMALL_FONT_SIZE * i, width, SMALL_FONT_SIZE + 5);
            [l setTextColor:[UIColor whiteColor]];

            [custom addSubview:l];

            if (width > maxWidth)
                maxWidth = width;
            i++;

        }
        
    }

    _detailView = [[CODialog alloc] initWithWindow:[[[UIApplication sharedApplication] delegate] window]];
    _detailView.dialogStyle = CODialogStyleCustomView;

    extensionTypeFound = UNKNOWN_EXTENSION;
    extensionTypeFound = [self findFileType: [key pathExtension]]; // testing to see if file can be open

    for (NSString *b in self.actionSheetButtons) {
        
        //NSLog(@"%@", b);
        if ([b isEqualToString:@"Open"] && !(extensionTypeFound & UNKNOWN_EXTENSION) && ![[dict objectForKey:@"type"] boolValue])
            [self.detailView addButtonWithTitle:b
                                         target:self
                                       selector:@selector(detailedVeiwButtonPressed:)];
        else if ([b isEqualToString:@"Email"] && ![[dict objectForKey:@"type"] boolValue])
            [self.detailView addButtonWithTitle:b
                                         target:self
                                       selector:@selector(detailedVeiwButtonPressed:)];
        else if (![b isEqualToString:@"Open"] && ![b isEqualToString:@"Email"])
            [self.detailView addButtonWithTitle:b
                                         target:self
                                       selector:@selector(detailedVeiwButtonPressed:)];

    }

    [self.detailView setTitle:[NSString stringWithFormat:@"File/Directory details for: %@", key]];
    custom.frame = CGRectMake(0, 0, self.detailView.bounds.size.width - LARGE_FONT_SIZE * 2, i * (SMALL_FONT_SIZE + 5));
    custom.contentSize = CGSizeMake(maxWidth + LARGE_FONT_SIZE, custom.frame.size.height);
    self.detailView.customView = custom;

    selectedDict = dict;
    selectedKey = key;
    [self.detailView showOrUpdateAnimated:NO];

}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.filesArray count];

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return CELL_HEIGHT;

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // fetch cell
    static NSString *cellID = @"filesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil) {

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.5;
        [cell addGestureRecognizer:longPress];

    }

    // fecthc key and dict info
    NSDictionary *dict = [self.filesArray objectAtIndex:indexPath.row];
    NSString *key = [dict objectForKey:@"name"];

    // set up cell text and other atributes
    //cell.detailTextLabel.text = [NSString stringWithUTF8String:self.iPadState.currentPath];
    if ([[dict objectForKey:@"type"] boolValue]) {

        cell.textLabel.text = [NSString stringWithFormat:@"📂 %@", key];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    }
    else {

        cell.textLabel.text = [NSString stringWithFormat:@"📄 %@", key];
        cell.accessoryType = UITableViewCellAccessoryNone;

    }
    cell.textLabel.font = [UIFont boldSystemFontOfSize:LARGE_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];

    return cell;

}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch data from keys and dictionary
    NSDictionary *dict = [self.filesArray objectAtIndex:indexPath.row];
    NSString *key = [dict objectForKey:@"name"];

    // if the dict object is a directory then...
    if ([[dict objectForKey:@"type"] boolValue]) {

        // set up state for subTableViewController
        NSString *subPath = [NSString stringWithFormat:@"%@%@", self.iPadState.currentPath, key];

        // Make subTableviewcontroller to push onto nav stack
        IPadTableViewController *subTableViewController = [[IPadTableViewController alloc] initWithPath:subPath
                                                                                               ipAddress:self.iPadState.ipAddress
                                                                                                   port:self.iPadState.port
                                                                                            switchAction:self.switchAction
                                                                                              forEvents:self.switchEvents
                                                                                             pathAction:self.pathAction
                                                                                             pathEvents:self.pathEvents];

        // push new controller onto nav stack
        [self.navigationController pushViewController:subTableViewController animated:YES];

    }

    // else dict object is a file then...
    else
        [self displayDetailedViwForItem:dict WithKey:key];

}

//-(void)tableView:(UITableView *)tableView did {

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end