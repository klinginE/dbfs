//
//  IPadTableViewController.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import "IPadTableViewController.h"
#import <string.h>
#import <assert.h>

@interface IPadTableViewController ()

@property (strong, atomic) NSMutableArray *alerts;
@property (weak, nonatomic) MobileDriveAppDelegate *appDelegate;
@property (assign) SEL switchAction;
@property (strong, atomic) UISwitch *conectSwitch;
@property (assign) UIControlEvents switchEvents;
@property (assign) SEL pathAction;
@property (assign) UIControlEvents pathEvents;
@property (strong, nonatomic) NSDictionary *filesDictionary;
@property (strong, nonatomic) NSArray *fileKeys;
@property (strong, nonatomic) UIScrollView *helpScroll;
@property (strong, nonatomic) UILabel *helpView;
@property (strong, nonatomic) UITableView *mainTableView;
@property (strong, nonatomic) UIView *pathView;
@property (strong, nonatomic) UIColor *barColor;
@property (strong, nonatomic) NSMutableArray *actionSheetButtons;
@property (strong, nonatomic) UIColor *buttonColor;

@end

@implementation IPadTableViewController

-(id)initWithPath:(NSString *)currentPath
         ipAddress:(NSString *)ip
           target:(MobileDriveAppDelegate *)respond
     switchAction:(SEL)action
        forEvents:(UIControlEvents)events
       pathAction:(SEL)pAction
       pathEvents:(UIControlEvents)pEvents {

    self = [super init];
    if (self) {

        // init state
        [self initState:&_iPadState WithPath:currentPath Address:ip];
        self.title = [NSString stringWithUTF8String:_iPadState.currentDir];

        // Set up back button
        [self.navigationItem setBackBarButtonItem:[self makeBarButtonWithTitle:self.title
                                                                           Tag:BACK_BUTTON_TAG
                                                                        Target:nil
                                                                        Action:nil]];

        _buttonColor = [UIColor colorWithRed:(0.0/255.0)
                                       green:(0.0/255.0)
                                        blue:(255.0/255.0)
                                       alpha:1.0f];
        _barColor = [UIColor colorWithRed:0.75f
                                    green:0.75f
                                     blue:0.75f
                                    alpha:1.0f];

        // set up connection switch
        _appDelegate = respond;
        _switchAction = action;
        _switchEvents = events;
        _conectSwitch = [[UISwitch alloc] init];
        [_conectSwitch addTarget:_appDelegate
                          action:_switchAction
                forControlEvents:events];
        if (respond.isConnected)
            _conectSwitch.on = YES;
        else
            _conectSwitch.on = NO;

        _pathAction = pAction;
        _pathEvents = pEvents;

        //Set up alerts
        _alerts = [[NSMutableArray alloc] init];
        [self initAlerts:_alerts];

        _actionSheetButtons = [[NSMutableArray alloc] init];
        [self initActionSheetButtons:_actionSheetButtons];

    }

    return self;

}

-(void)initState:(State *)state WithPath:(NSString *)path Address:(NSString *)ip {

    state->currentPath = [self nsStringToCString:path];
    state->ipAddress = [self nsStringToCString:ip];
    NSUInteger len = [path length];
    assert(len > 0);
    assert([path characterAtIndex:0] == '/');
    NSUInteger index = len - 1;

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

    if (self.pathView && self.view) {

        UILabel *ipLabel = [[UILabel alloc] init];
        ipLabel.text = [NSString stringWithFormat:@"IP Address: %@", [NSString stringWithUTF8String:self.iPadState.ipAddress]];
        ipLabel.font = [UIFont systemFontOfSize:SMALL_FONT_SIZE];
        ipLabel.frame = CGRectMake(self.pathView.frame.origin.x + self.pathView.frame.size.width / 2.0,
                                             self.view.frame.origin.y + PATH_VIEW_HEIGHT / 2.0,
                                             [self sizeOfString:ipLabel.text withFont:ipLabel.font].width,
                                             PATH_VIEW_HEIGHT/2.0);
        [self.pathView addSubview:ipLabel];

        NSString *title = @"/";
        NSInteger len = 0;
        UILabel *currentPath = [[UILabel alloc] init];
        currentPath.text = @"Path: ";
        [currentPath setFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]];
        [currentPath setFrame:CGRectMake(0, self.view.frame.origin.y, [self sizeOfString:currentPath.text withFont:currentPath.font].width, PATH_VIEW_HEIGHT/ 2.0)];

        [self.pathView addSubview:currentPath];

        for (int i = 1; i <= (self.iPadState.depth + 1); i++) {

            title = [self dirAtDepth:(i - 1)
                              InPath:[NSString stringWithUTF8String:self.iPadState.currentPath]];

            UIButton *pathButton = [self makeButtonWithTitle:title
                                                         Tag:(i - 1)
                                                      Target:self.appDelegate
                                                      Action:action
                                                     ForEvents:events];

            pathButton.frame = CGRectMake([self sizeOfString:currentPath.text withFont:currentPath.font].width + self.view.frame.origin.x + len,
                                          self.view.frame.origin.y,
                                          [self sizeOfString:title withFont:pathButton.titleLabel.font].width,
                                          PATH_VIEW_HEIGHT/2.0);
            pathButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

            if (i == (self.iPadState.depth + 1)) {

                [pathButton setEnabled:NO];
                [pathButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];

            }
            len += [self sizeOfString:title withFont:pathButton.titleLabel.font].width;

            [self.pathView addSubview:pathButton];

        }

    }

}

-(void)dealloc {

    //NSLog(@"dealloc");
    [self freeState:self.iPadState];
    self.alerts = nil;
    self.conectSwitch = nil;
    self.filesDictionary = nil;
    self.fileKeys = nil;
    self.helpScroll = nil;
    self.helpView = nil;
    self.mainTableView = nil;
    self.pathView = nil;
    self.barColor = nil;
    self.actionSheetButtons = nil;
    self.buttonColor = nil;

}

-(void)freeState:(State)state {

    //This assumes that the strings were created on the heap
    if (state.currentDir != NULL)
        free(state.currentDir);
    if (state.currentPath != NULL)
        free(state.currentPath);
    if (state.ipAddress != NULL)
        free(state.ipAddress);

}

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

-(UIBarButtonItem *)makeBarButtonWithTitle:(NSString *)title
                                       Tag:(NSInteger)tag
                                    Target:(id)target
                                    Action:(SEL)action {

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title
                                                               style:UIBarButtonItemStyleBordered
                                                              target:target
                                                              action:action];
    [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize: LARGE_FONT_SIZE],
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
    [button.titleLabel setFont:[UIFont systemFontOfSize:SMALL_FONT_SIZE]];
    button.tag = tag;
    [button setTitleColor:self.buttonColor forState:UIControlStateNormal];

    return button;

}

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font {

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size];

}

-(void)makeFrameForViews {

    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    CGFloat mainScreenWidth = mainScreenBounds.size.width;
    CGFloat mainScreenHeight = mainScreenBounds.size.height;
    CGFloat textHeight = mainScreenHeight;
    
    if([self interfaceOrientation] == UIInterfaceOrientationLandscapeLeft ||
       [self interfaceOrientation] == UIInterfaceOrientationLandscapeRight) {
        
        CGFloat temp = mainScreenWidth;
        mainScreenWidth = mainScreenHeight;
        mainScreenHeight = temp;
        textHeight = mainScreenWidth;

    }

    if (self.pathView)
        self.pathView.frame = CGRectMake(0,
                                         self.navigationController.navigationBar.frame.origin.y + self. navigationController.navigationBar.frame.size.height,
                                         mainScreenWidth,
                                         PATH_VIEW_HEIGHT);
    if (self.mainTableView)
        self.mainTableView.frame = CGRectMake(0,
                                              self.pathView.frame.origin.y + PATH_VIEW_HEIGHT,
                                              mainScreenWidth,
                                              mainScreenHeight - self.pathView.frame.origin.y - PATH_VIEW_HEIGHT - self.navigationController.toolbar.frame.size.height);
    if (self.view)
        self.view.frame = CGRectMake(0,
                                     0,
                                     mainScreenWidth,
                                     self.mainTableView.frame.size.height + PATH_VIEW_HEIGHT);
    if (self.helpView)
        self.helpView.frame = CGRectMake(LARGE_FONT_SIZE,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         textHeight);

    if (self.helpScroll && self.helpView) {

        self.helpScroll.frame = CGRectMake(self.view.frame.origin.x,
                                           self.view.frame.origin.y,
                                           self.view.frame.size.width,
                                           mainScreenHeight);
        self.helpScroll.contentSize = CGSizeMake(self.helpView.frame.size.width,
                                                 self.helpView.frame.size.height);

    }

}

-(void)loadView {

    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    CGFloat mainScreenWidth = mainScreenBounds.size.width;
    CGFloat mainScreenHeight = mainScreenBounds.size.height;

    if([self interfaceOrientation] == UIInterfaceOrientationLandscapeLeft ||
       [self interfaceOrientation] == UIInterfaceOrientationLandscapeRight) {

        CGFloat temp = mainScreenWidth;
        mainScreenWidth = mainScreenHeight;
        mainScreenHeight = temp;

    }

    self.mainTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                      style:UITableViewStylePlain];
    self.mainTableView.dataSource = self;
    self.mainTableView.delegate = self;

    self.pathView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.pathView setBackgroundColor:self.barColor];

    UIView *mainView = [[UIView alloc] initWithFrame:CGRectZero];
    self.view = mainView;

    [self.view addSubview:self.pathView];
    [self.view addSubview:self.mainTableView];
    [self initPathViewWithAction:self.pathAction ForEvents:self.pathEvents];
    [self makeFrameForViews];

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

        //FIXME change for grabing info from plist and instead grab data from model
        NSString *path = [[NSBundle mainBundle] pathForResource:@"files" ofType:@"plist"];
        _filesDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        _fileKeys = [[_filesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
        //[self.appDelegate.model getDirectoryListIn:[NSString stringWithUTF8String:self.iPadState.currentPath]];

    }

    // Get colors
    UIColor *toolBarColor = [UIColor colorWithRed:0.65f
                                            green:0.65f
                                             blue:0.65f
                                            alpha:1.0f];

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

    // make lable for switch
    NSString *switchString = @"Turn on/off server:";
    UILabel *switchLable = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     [self sizeOfString:switchString
                                                                               withFont:[UIFont systemFontOfSize: LARGE_FONT_SIZE]].width,
                                                                     CELL_HEIGHT)];
    switchLable.text = switchString;
    switchLable.backgroundColor = [UIColor clearColor];
    switchLable.textColor = [UIColor blackColor];
    switchLable.font = [UIFont systemFontOfSize:LARGE_FONT_SIZE];
    [switchLable setTextAlignment:NSTextAlignmentCenter];
    UIBarButtonItem *switchButtonItem = [[UIBarButtonItem alloc] initWithCustomView:switchLable];

    // add switch to the bottom right
    UIBarButtonItem *cSwitch = [[UIBarButtonItem alloc] initWithCustomView:self.conectSwitch];

    // put objects in toolbar
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:addDirButton, flex, switchButtonItem, cSwitch, nil];
    self.toolbarItems = toolBarItems;

    // set tool bar settings
    self.navigationController.toolbar.barTintColor = toolBarColor;
    [self.navigationController.toolbar setOpaque:YES];

    // set navbar settings
    self.navigationController.navigationBar.barTintColor = self.barColor;
    self.navigationController.navigationBar.tintColor = self.buttonColor;
    [self.navigationController setToolbarHidden:NO animated:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

-(void)viewWillAppear:(BOOL)animated {

    self.conectSwitch.on = self.appDelegate.isConnected;
    [super viewWillAppear:animated];

}

-(void)orientationChanged:(NSNotification *)note {

    NSLog(@"Rotated!");
    [self makeFrameForViews];

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != 0) {

        static NSString *text = @"";
        static alertTag previousTag = NONE;

        switch (alertView.tag) {

            case ADD_ALERT_TAG:
                previousTag = ADD_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_ALERT_TAG] show];
                break;
            case DELETE_ALERT_TAG:
                //FIXME add code here to delete
                break;
            case MOVE_ALERT_TAG:
                previousTag = MOVE_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_ALERT_TAG] show];
                break;
            case RENAME_ALERT_TAG:
                previousTag = RENAME_ALERT_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_ALERT_TAG] show];
                break;
            case CONFIRM_ALERT_TAG:
                NSLog(@"Entered= %@", text);
                switch (previousTag) {

                    case ADD_ALERT_TAG:
                        //FIXME add code here to add a directory
                        break;
                    case MOVE_ALERT_TAG:
                        //FIXME add code here to move a file/directory
                        break;
                    case RENAME_ALERT_TAG:
                        //FIXME add code here to rename a file/directory
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

-(UIAlertView *)objectInArray:(NSArray *)a WithTag:(NSInteger)tag {

    for (UIAlertView *object in a)
        if(object.tag == tag)
            return object;

    return nil;

}

-(void)displayHelpPage {
    
    NSString *helpMessagePath = [[NSBundle mainBundle] pathForResource:@"helpPage" ofType:@"txt"];
    NSString *helpMessage = [NSString stringWithContentsOfFile:helpMessagePath encoding:NSUTF8StringEncoding error:NULL];

    _helpView = [[UILabel alloc] initWithFrame:CGRectZero];
    _helpView.text = helpMessage;
    _helpView.backgroundColor = [UIColor clearColor];
    _helpView.textColor = [UIColor blackColor];
    _helpView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    _helpView.numberOfLines = 0;
    [_helpView sizeToFit];
    
    _helpScroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [_helpScroll addSubview:_helpView];
    [_helpScroll setScrollEnabled:YES];
    [_helpScroll setBounces:NO];

    UIViewController *helpController = [[UIViewController alloc] init];
    helpController.title = @"Help Page.";

    [helpController.view addSubview:_helpScroll];
    [self makeFrameForViews];
    [self.navigationController pushViewController:helpController animated:YES];
    
}

-(void)displayAddDirPage {

    UIAlertView *addDirAlert = [self objectInArray:self.alerts WithTag:ADD_ALERT_TAG];
    [addDirAlert show];

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

-(void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

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
    cell.detailTextLabel.text = [dict objectForKey:@"path"];
    if ([[dict objectForKey:@"isDir"] boolValue]) {

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

-(char *)nsStringToCString:(NSString *)s {

    NSInteger len = [s length];
    char *c = (char *)malloc(len + 1);
    NSInteger i = 0;
    for (; i < len; i++)
        c[i] = [s characterAtIndex:i];
    c[i] = '\0';

    return c;

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Move"])
        [[self objectInArray:self.alerts WithTag:MOVE_ALERT_TAG] show];
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Rename"])
        [[self objectInArray:self.alerts WithTag:RENAME_ALERT_TAG] show];
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"])
        [[self objectInArray:self.alerts WithTag:DELETE_ALERT_TAG] show];

}

-(void)displayDetailedViwForItem:(NSDictionary *)dict WithKey:(NSString *)key {

    UIActionSheet *detailSheet = [[UIActionSheet alloc] init];
    [detailSheet setTitle:@"File/Directory Details"];
    [detailSheet setDelegate:self];
    for (NSString *button in self.actionSheetButtons)
        [detailSheet addButtonWithTitle:button];
    [detailSheet setCancelButtonIndex:([self.actionSheetButtons count] - 1)];

    [detailSheet showInView:self.view];
    CGRect rect = detailSheet.frame;
    rect.origin.y += SMALL_FONT_SIZE * 2;
    rect.size.height = SMALL_FONT_SIZE * 6;
    UIView *detailView = [[UIView alloc] initWithFrame:rect];
    [detailView setBackgroundColor:detailSheet.backgroundColor];
    [detailSheet addSubview:detailView];

    CGRect rect2 = detailSheet.frame;
    rect2.size.height += rect.size.height;
    detailSheet.frame = rect2;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch data from keys and dictionary
    NSString *key = [self.fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [self.filesDictionary objectForKey:key];

    // if the dict object is a directory then...
    if ([[dict objectForKey:@"isDir"] boolValue]) {

        // set up state for subTableViewController
        NSString *subPath = [NSString stringWithFormat:@"%s%@", self.iPadState.currentPath, key];

        // Make subTableviewcontroller to push onto nav stack
        IPadTableViewController *subTableViewController = [[IPadTableViewController alloc] initWithPath:subPath
                                                                                               ipAddress:[NSString stringWithUTF8String:self.iPadState.ipAddress]
                                                                                                  target:self.appDelegate
                                                                                            switchAction:self.switchAction
                                                                                              forEvents:self.switchEvents pathAction:self.pathAction pathEvents:self.pathEvents];

        // push new controller onto nav stack
        [self.navigationController pushViewController:subTableViewController animated:YES];

    }

    // else dict object is a file then...
    else
        [self displayDetailedViwForItem:dict WithKey:key];

}

-(void)handleLongPress:(UILongPressGestureRecognizer*)sender {

    CGPoint location = [sender locationInView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    NSString *key = [self.fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [self.filesDictionary objectForKey:key];

    if (sender.state == UIGestureRecognizerStateBegan)
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