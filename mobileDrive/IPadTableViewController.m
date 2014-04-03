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

@interface IPadTableViewController ()

// Private Properties
// State
@property (weak, nonatomic) MobileDriveAppDelegate *appDelegate;
@property (strong, nonatomic) NSDictionary *filesDictionary;
@property (strong, nonatomic) NSArray *fileKeys;

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

@end

@implementation IPadTableViewController {

    NSDictionary *selectedDict;
    NSString *selectedKey;

}

#pragma mark - Initers

-(id)initWithPath:(NSString *)currentPath
         ipAddress:(NSString *)ip
     switchAction:(SEL)sAction
        forEvents:(UIControlEvents)sEvents
       pathAction:(SEL)pAction
       pathEvents:(UIControlEvents)pEvents {

    self = [super init];
    if (self) {

        // init State
        [self initState:&_iPadState WithPath:currentPath Address:ip];
        _appDelegate = (MobileDriveAppDelegate *)[UIApplication sharedApplication].delegate;
        self.title = [NSString stringWithUTF8String:_iPadState.currentDir];
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

-(void)initState:(State *)state WithPath:(NSString *)path Address:(NSString *)ip {

    state->currentPath = [self nsStringToCString:path];
    state->ipAddress = [self nsStringToCString:ip];
    NSUInteger len = [path length];
    NSUInteger index = len - 1;

    assert(len > 0);
    assert([path characterAtIndex:0] == '/');

    if (index)
        for (; [path characterAtIndex:index - 1] != '/'; index--);
    state->currentDir = [self nsStringToCString:[path substringFromIndex:index]];

    state->depth = 0;
    for (int i = 0; i < (len - 1); i++)
        if ([path characterAtIndex:i] == '/')
            state->depth++;

    NSLog(@"dir= %s", state->currentDir);
    NSLog(@"path= %s", state->currentPath);
    NSLog(@"depth= %d", state->depth);

}

-(void)initAlerts:(NSMutableArray *)alerts {

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
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Renaming a File/Directory"];
                [alert setMessage:@"Give it a new name:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = RENAME_ALERT_TAG;
                break;
            case CONFIRM_ALERT_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"This action is permanent!"];
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
            default:
                break;

        }

        [alerts addObject:alert];

    }

}

-(void)initActionSheetButtons:(NSMutableArray *)buttons {

    [buttons addObject:@"Move"];
    [buttons addObject:@"Rename"];
    [buttons addObject:@"Delete"];
    [buttons addObject:@"Cancel"];

}

-(void)initPathViewWithAction:(SEL)action ForEvents:(UIControlEvents)events {

    UIFont *textFont = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    CGSize currentPathSize = [self sizeOfString:[NSString stringWithUTF8String:self.iPadState.currentPath]
                                       withFont:textFont];

    UILabel *pathLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    pathLabel.text = @"Path: ";
    CGFloat pathY = (PATH_VIEW_HEIGHT - MEDIAN_FONT_SIZE)/ 4.0;
    [pathLabel setFont:self.pathLabelView.font];
    [pathLabel setFrame:CGRectMake(SMALL_FONT_SIZE,
                                   pathY,
                                   [self sizeOfString:pathLabel.text withFont:textFont].width,
                                   MEDIAN_FONT_SIZE)];
    [self.pathScrollView addSubview:pathLabel];
    CGSize pathLabelSize = [self sizeOfString:pathLabel.text withFont:textFont];

    self.pathLabelView.text = pathLabel.text.copy;
    [self.pathLabelView setFont:textFont];
    [self.pathLabelView setFrame:CGRectMake(SMALL_FONT_SIZE,
                                            pathY,
                                            currentPathSize.width + pathLabelSize.width,
                                            currentPathSize.height)];
    

    NSString *title = @"/";
    NSInteger len = 0;
    for (int i = 1; i <= (self.iPadState.depth + 1); i++) {

        title = [self dirAtDepth:(i - 1)
                          InPath:[NSString stringWithUTF8String:self.iPadState.currentPath]];

        UIButton *pathButton = [self makeButtonWithTitle:title
                                                     Tag:(i - 1)
                                                  Target:self.appDelegate
                                                  Action:action
                                               ForEvents:events];
        CGSize titleSize = [self sizeOfString:title withFont:pathButton.titleLabel.font];

        pathButton.frame = CGRectMake(self.view.frame.origin.x + SMALL_FONT_SIZE + pathLabelSize.width + len,
                                      pathY,
                                      titleSize.width,
                                      MEDIAN_FONT_SIZE);
        pathButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

        if (i == (self.iPadState.depth + 1)) {

            [pathButton setEnabled:NO];
            [pathButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];

        }
        len += titleSize.width;
        [self.pathScrollView addSubview:pathButton];
        self.pathLabelView.text = [NSString stringWithFormat:@"%@%@",
                                   self.pathLabelView.text,
                                   pathButton.titleLabel.text];

    }

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

        self.pathScrollView.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y + self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height,
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
    [self.navigationItem setBackBarButtonItem:[self makeBarButtonWithTitle:self.title
                                                                       Tag:BACK_BUTTON_TAG
                                                                    Target:nil
                                                                    Action:nil]];

    self.view = [[UIView alloc] initWithFrame:CGRectZero];

    [self makeFrameForViews];
    [self.view addSubview:self.pathScrollView];
    [self.view addSubview:self.mainTableView];

}

#pragma mark - Deallocs

-(void)freeState:(State)state {

    //This assumes that the strings were created on the heap
    if (state.currentDir != NULL)
        free(state.currentDir);
    if (state.currentPath != NULL)
        free(state.currentPath);
    if (state.ipAddress != NULL)
        free(state.ipAddress);

}

-(void)dealloc {

    //NSLog(@"dealloc");
    // Free state
    [self freeState:self.iPadState];
    self.filesDictionary = nil;
    self.fileKeys = nil;

    // Free Views
    self.alertViews = nil;
    self.actionSheetButtons = nil;
    self.conectSwitchView = nil;
    self.helpScrollView = nil;
    self.helpLabelView = nil;
    self.mainTableView = nil;
    self.pathScrollView = nil;
    self.detailView = nil;

    // Free Colors
    self.barColor = nil;
    self.buttonColor = nil;
    self.toolBarColor = nil;

}

#pragma mark - Setters

-(void)setIPAdress:(NSString *)ip {

    free(_iPadState.ipAddress);
    _iPadState.ipAddress = [self nsStringToCString:ip];
    for (UIViewController *vc in [self.navigationController viewControllers])
        for (UIBarButtonItem *bi in vc.toolbarItems)
            if (bi.tag == IP_TAG) {

                UILabel *newLabel = [[UILabel alloc] init];
                newLabel.text = [NSString stringWithFormat:@"IP Address: %@", ip];
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

#pragma mark - Converters

-(char *)nsStringToCString:(NSString *)s {
    
    NSInteger len = [s length];
    char *c = (char *)malloc(len + 1);
    NSInteger i = 0;
    for (; i < len; i++)
        c[i] = [s characterAtIndex:i];
    c[i] = '\0';
    
    return c;
    
}

#pragma mark - Event Handelers

-(void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    self.conectSwitchView.on = self.appDelegate.isConnected;
    
    if (self.filesDictionary && self.fileKeys && self.mainTableView) {

        self.filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];
        self.fileKeys = [self.filesDictionary allKeys];
        [self.mainTableView reloadData];

    }

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
                if (str && len && [str characterAtIndex:(len - 1)] == '/') {
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
                if (str && len && [str characterAtIndex:(len - 1)] == '/')
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

                    NSString *path = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, selectedKey];
                    BOOL isDir = [[selectedDict objectForKey:@"Type"] boolValue];

                    if ([self strOkay:selectedKey ForTag:DELETE_ALERT_TAG IsDir:isDir]) {

                        DBFS_Error err = DBFS_OKAY;
                        if (isDir)
                            err = [self.appDelegate.model deleteDirectory:path];
                        else
                            err = [self.appDelegate.model deleteFile:path];
                        if (err == DBFS_OKAY) {

                            self.filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String: self.iPadState.currentPath]];
                            self.fileKeys = [self.filesDictionary allKeys];
                            [self.mainTableView reloadData];

                        }
                        else {
                            NSLog(@"DBFS Not OK with DELETE");
                            //FIXME add code here to deal with DBFS_Error
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

                        NSString *path = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, text];

                        if ([text characterAtIndex:0] != '/')
                            path = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, text];
                        else
                            path = text;
                        if ([path characterAtIndex:([path length] - 1)] != '/')
                            path = [NSString stringWithFormat:@"%@/", path];

                        if ([self strOkay:path ForTag:ADD_ALERT_TAG IsDir:YES]) {

                            DBFS_Error err = [self.appDelegate.model createDirectory:path];
                            if (err == DBFS_OKAY) {

                                self.filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];
                                self.fileKeys = [self.filesDictionary allKeys];
                                [self.mainTableView reloadData];

                            }
                            else {
                                NSLog(@"DBFS Not OK with ADD");
                                //FIXME add code here to deal with DBFS_Error
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

                            NSString *oldPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, selectedKey];
                            NSString *newPath = @"";
                            if ([text characterAtIndex:0] != '/')
                                newPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, text];
                            else
                                newPath = text;
                            BOOL isDir = [[selectedDict objectForKey:@"Type"] boolValue];
                            if (isDir && [newPath characterAtIndex:([newPath length] - 1)] != '/')
                                newPath = [NSString stringWithFormat:@"%@/", newPath];

                            NSInteger index = [newPath length] - [selectedKey length];
                            if (index < 0 || ![[newPath substringFromIndex:index] isEqualToString:selectedKey])
                                newPath = [NSString stringWithFormat:@"%@%@", newPath, selectedKey];

                            if ([self strOkay:oldPath ForTag:MOVE_ALERT_TAG IsDir:isDir] &&
                                [self strOkay:newPath ForTag:MOVE_ALERT_TAG IsDir:isDir]) {

                                DBFS_Error err = DBFS_OKAY;
                                if (isDir)
                                    err = [self.appDelegate.model moveDirectory:oldPath to:newPath];
                                else
                                    err = [self.appDelegate.model moveFile:oldPath to:newPath];
                                if (err == DBFS_OKAY) {

                                    self.filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];
                                    self.fileKeys = [self.filesDictionary allKeys];
                                    [self.mainTableView reloadData];

                                }
                                else {
                                    NSLog(@"DBFS Not OK with MOVE");
                                    //FIXME add code here to deal with DBFS_Error
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

                            BOOL isDir = [[selectedDict objectForKey:@"Type"] boolValue];
                            if (isDir && [text characterAtIndex:([text length] - 1)] != '/')
                                text = [NSString stringWithFormat:@"%@/", text];

                            NSString *oldPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, selectedKey];
                            NSString *newPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, text];

                            if ([self strOkay:selectedKey ForTag:RENAME_ALERT_TAG IsDir:isDir] &&
                                [self strOkay:text ForTag:RENAME_ALERT_TAG IsDir:isDir]) {

                                DBFS_Error err = DBFS_OKAY;
                                if (isDir)
                                    err = [self.appDelegate.model renameDirectory:oldPath to:newPath];
                                else
                                    err = [self.appDelegate.model renameFile:oldPath to:newPath];
                                if (err == DBFS_OKAY) {

                                    self.filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];
                                    self.fileKeys = [self.filesDictionary allKeys];
                                    [self.mainTableView reloadData];

                                }
                                else {
                                    NSLog(@"DBFS Not OK With RENAME");
                                    //FIXME add code here to deal with DBFS_Error
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
            default:
                previousTag = NONE;
                break;

        }

    }
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
        [alertView textFieldAtIndex:0].text = @"";

}

-(void)buttonPressed:(UIBarButtonItem *)sender {

    //NSLog(@"buttonPressed: %d", sender.tag);
    switch (sender.tag) {

        case HELP_BUTTON_TAG:
            [self displayHelpPage];
            break;
        case ADD_DIR_BUTTON_TAG:
            [self displayAddDirPage];
            break;
        default:
            break;

    }

}

-(void)detailedVeiwButtonPressed:(UIButton *)sender {

    [self.detailView hideAnimated:NO];
    if ([sender.titleLabel.text isEqualToString:@"Move"])
        [[self objectInArray:self.alertViews WithTag:MOVE_ALERT_TAG] show];
    else if ([sender.titleLabel.text isEqualToString:@"Rename"])
        [[self objectInArray:self.alertViews WithTag:RENAME_ALERT_TAG] show];
    else if ([sender.titleLabel.text isEqualToString:@"Delete"])
        [[self objectInArray:self.alertViews WithTag:DELETE_ALERT_TAG] show];

}

-(void)handleLongPress:(UILongPressGestureRecognizer*)sender {

    CGPoint location = [sender locationInView:self.mainTableView];
    NSIndexPath *indexPath = [self.mainTableView indexPathForRowAtPoint:location];
    NSString *key = [self.fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [self.filesDictionary objectForKey:key];

    if (sender.state == UIGestureRecognizerStateBegan)
        [self displayDetailedViwForItem:dict WithKey:key];

}

-(void)viewDidLoad {

    [super viewDidLoad];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];

    // Set up directory Contents
    if(_filesDictionary == nil) {

        //NSString *path = [[NSBundle mainBundle] pathForResource:@"files" ofType:@"plist"];
        //_filesDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        //_fileKeys = [[_filesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];

        _filesDictionary = [self.appDelegate.model getContentsIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];
        _fileKeys = [_filesDictionary allKeys];

    }

    // Add a help button to the top right
    UIBarButtonItem *helpButton = [self makeBarButtonWithTitle:@"Need help?"
                                                           Tag:HELP_BUTTON_TAG
                                                        Target:self
                                                        Action:@selector(buttonPressed:)];
    self.navigationItem.rightBarButtonItem = helpButton;

    // Add a add dir button to the bottom left
    UIBarButtonItem *addDirButton = [self makeBarButtonWithTitle:@"Add Directory"
                                                             Tag:ADD_DIR_BUTTON_TAG
                                                          Target:self
                                                          Action:@selector(buttonPressed:)];

    // flexiable space holder
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];
    UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];

    UILabel *ipLabel = [[UILabel alloc] init];
    ipLabel.text = [NSString stringWithFormat:@"IP Address: %@", [NSString stringWithUTF8String:self.iPadState.ipAddress]];
    ipLabel.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    ipLabel.frame = CGRectMake(0,
                               0,
                               [self sizeOfString:ipLabel.text withFont:ipLabel.font].width,
                               MEDIAN_FONT_SIZE);
    UIBarButtonItem *ipButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ipLabel];
    ipButtonItem.tag = IP_TAG;

    // make lable for switch
    NSString *switchString = @"Turn on/off server:";
    UILabel *switchLable = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     [self sizeOfString:switchString
                                                                               withFont:[UIFont systemFontOfSize: MEDIAN_FONT_SIZE]].width,
                                                                     CELL_HEIGHT)];
    switchLable.text = switchString;
    switchLable.backgroundColor = [UIColor clearColor];
    switchLable.textColor = [UIColor blackColor];
    switchLable.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    [switchLable setTextAlignment:NSTextAlignmentCenter];
    UIBarButtonItem *switchButtonItem = [[UIBarButtonItem alloc] initWithCustomView:switchLable];

    // add switch to the bottom right
    UIBarButtonItem *cSwitch = [[UIBarButtonItem alloc] initWithCustomView:self.conectSwitchView];

    // put objects in toolbar
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:addDirButton, flex, ipButtonItem, flex2, switchButtonItem, cSwitch, nil];
    self.toolbarItems = toolBarItems;

    // set tool bar settings
    self.navigationController.toolbar.barTintColor = self.toolBarColor;
    [self.navigationController.toolbar setOpaque:YES];

    // set navbar settings
    self.navigationController.navigationBar.barTintColor = self.barColor;
    self.navigationController.navigationBar.tintColor = self.buttonColor;
    [self.navigationController setToolbarHidden:NO animated:YES];

    [self.tableView reloadData];
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
    helpController.title = @"Help Page.";

    [helpController.view addSubview:self.helpScrollView];
    [self makeFrameForViews];
    [self.navigationController pushViewController:helpController animated:YES];

}

-(void)displayAddDirPage {

    UIAlertView *addDirAlert = [self objectInArray:self.alertViews WithTag:ADD_ALERT_TAG];
    [addDirAlert show];

}

-(void)displayDetailedViwForItem:(NSDictionary *)dict WithKey:(NSString *)key {

    UIScrollView *custom = [[UIScrollView alloc] initWithFrame:CGRectZero];
    int i = 1;
    CGFloat maxWidth = 0;
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = [NSString stringWithFormat:@"Name: %@", key];
    nameLabel.frame = CGRectMake(0, 0, [self sizeOfString:nameLabel.text withFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]].width, SMALL_FONT_SIZE);
    [nameLabel setTextColor:[UIColor whiteColor]];
    [nameLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]];
    
    [custom setBackgroundColor:[UIColor clearColor]];
    [custom setBounces:NO];
    
    [custom addSubview:nameLabel];
    
    for (NSString *k in [dict keyEnumerator]) {
        
        UILabel *l = [[UILabel alloc] init];
        l.text = [NSString stringWithFormat:@"%@: %@", k, [dict objectForKey:k]];
        [l setFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]];
        CGFloat width = [self sizeOfString:l.text
                                  withFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]].width;
        l.frame = CGRectMake(0, SMALL_FONT_SIZE * i, width, SMALL_FONT_SIZE);
        [l setTextColor:[UIColor whiteColor]];
        [custom addSubview:l];
        
        if (width > maxWidth)
            maxWidth = width;
        i++;
        
    }

    if (!self.detailView) {

        _detailView = [[CODialog alloc] initWithWindow:[[[UIApplication sharedApplication] delegate] window]];
        [_detailView setTitle:@"File/Directory details:"];
        _detailView.dialogStyle = CODialogStyleCustomView;

        for (NSString *b in self.actionSheetButtons)
            [self.detailView addButtonWithTitle:b
                                         target:self
                                       selector:@selector(detailedVeiwButtonPressed:)];

    }
    self.detailView.customView = custom;

    selectedDict = dict;
    selectedKey = key;
    [self.detailView showOrUpdateAnimated:NO];
    custom.frame = CGRectMake(0, 0, self.detailView.bounds.size.width - LARGE_FONT_SIZE * 2, (i + 1) * SMALL_FONT_SIZE);
    custom.contentSize = CGSizeMake(maxWidth + LARGE_FONT_SIZE, custom.frame.size.height);

}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.fileKeys count];

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
    NSString *key = [self.fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [self.filesDictionary objectForKey:key];

    // set up cell text and other atributes
    //cell.detailTextLabel.text = [NSString stringWithUTF8String:self.iPadState.currentPath];
    if ([[dict objectForKey:@"Type"] boolValue]) {

        cell.textLabel.text = [NSString stringWithFormat:@"📂 %@", key];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    }
    else
        cell.textLabel.text = [NSString stringWithFormat:@"📄 %@", key];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:LARGE_FONT_SIZE];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];

    return cell;

}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch data from keys and dictionary
    NSString *key = [self.fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [self.filesDictionary objectForKey:key];

    // if the dict object is a directory then...
    if ([[dict objectForKey:@"Type"] boolValue]) {

        // set up state for subTableViewController
        NSString *subPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, key];

        // Make subTableviewcontroller to push onto nav stack
        IPadTableViewController *subTableViewController = [[IPadTableViewController alloc] initWithPath:subPath
                                                                                               ipAddress:[NSString stringWithUTF8String:self.iPadState.ipAddress]
                                                                                            switchAction:self.switchAction
                                                                                              forEvents:self.switchEvents pathAction:self.pathAction pathEvents:self.pathEvents];

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