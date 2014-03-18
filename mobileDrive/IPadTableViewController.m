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

@property (strong, atomic)NSMutableArray *alerts;
@property (weak, nonatomic)MobileDriveAppDelegate *appDelegate;
@property (assign) SEL switchAction;
@property (assign) State iPadState;
@property (strong, atomic) UISwitch *conectSwitch;
@property (assign) UIControlEvents switchEvents;
@property (strong, nonatomic) NSDictionary *filesDictionary;
@property (strong, nonatomic) NSArray *fileKeys;
@property (strong, nonatomic) UIScrollView *helpScroll;
@property (strong, nonatomic) UILabel *helpView;
@property (strong, nonatomic) UITableView *mainTableView;
@property (strong, nonatomic) UIView *pathView;
@property (strong, nonatomic) UIColor *barColor;

@end

@implementation IPadTableViewController

-(id)initWithPath:(NSString *)currentPath
           target:(MobileDriveAppDelegate *)respond
     switchAction:(SEL)action
        forEvents:(UIControlEvents)events {

    self = [super init];
    if (self) {

        // init state
        [self initState:&_iPadState WithPath:currentPath];

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

        //Set up alerts
        _alerts = [[NSMutableArray alloc] init];
        [self initAlerts:_alerts];

    }

    return self;

}

-(void)initState:(State *)state WithPath:(NSString *)path {

    state->currentPath = [self nsStringToCString:path];
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

    for (int i = ADD_TAG; i < (NUM_ALERTS + ADD_TAG); i++) {

        UIAlertView *alert = [[UIAlertView alloc] init];
        switch (i) {
                
            case ADD_TAG:
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Add a Directory"];
                [alert setMessage:@"Give it a name:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = ADD_TAG;
                break;
            case DELETE_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"Deleting a File/Directory"];
                [alert setMessage:@"Are You Sure?"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = DELETE_TAG;
                break;
            case MOVE_TAG:
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Moving a File/Directory"];
                [alert setMessage:@"Give it a new path:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = MOVE_TAG;
                break;
            case RENAME_TAG:
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setDelegate:self];
                [alert setTitle:@"Renaming a File/Directory"];
                [alert setMessage:@"Give it a new name:"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = RENAME_TAG;
                break;
            case CONFIRM_TAG:
                [alert setDelegate:self];
                [alert setTitle:@"This action is permanent!"];
                [alert setMessage:@"Are you sure you want to perform this action?"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert addButtonWithTitle:@"OK"];
                alert.tag = CONFIRM_TAG;
                break;
            default:
                break;

        }

        [alerts addObject:alert];

    }

}

-(void)dealloc {

    //NSLog(@"dealloc");
    [self freeState:self.iPadState];

}

-(void)freeState:(State)state {

    //This assumes that the strings were created on the heap
    if (state.currentDir != NULL)
        free(state.currentDir);
    if (state.currentPath != NULL)
        free(state.currentPath);

}

-(UIBarButtonItem *)makeButtonWithTitle:(NSString *)title
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

-(CGSize)sizeOfString:(NSString *)string withFont:(UIFont *)font {

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size];

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

    self.mainTableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       self.navigationController.navigationBar.frame.size.height + PATH_VIEW_HEIGHT,
                                                                       mainScreenWidth,
                                                                       mainScreenHeight - self.navigationController.navigationBar.frame.size.height - PATH_VIEW_HEIGHT - self.navigationController.toolbar.frame.size.height)
                                                      style:UITableViewStylePlain];
    self.mainTableView.dataSource = self;
    self.mainTableView.delegate = self;

    self.pathView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                             self.navigationController.navigationBar.frame.size.height,
                                                             mainScreenWidth,
                                                             PATH_VIEW_HEIGHT)];
    [self.pathView setBackgroundColor:self.barColor];
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectZero];

    self.view = mainView;
    [self.view addSubview:self.pathView];
    [self.view addSubview:self.mainTableView];

}

- (void)viewDidLoad {

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
    UIBarButtonItem *helpButton = [self makeButtonWithTitle:@"Need help?"
                                                        Tag:HELP_TAG
                                                     Target:self
                                                     Action:@selector(buttonPressed:)];
    self.navigationItem.rightBarButtonItem = helpButton;

    // Add a add dir button to the bottom left
    UIBarButtonItem *addDirButton = [self makeButtonWithTitle:@"Add Directory"
                                                          Tag:ADD_DIR_TAG
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
    UIBarButtonItem *cSwitch = [[UIBarButtonItem alloc] initWithCustomView:_conectSwitch];

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

    _conectSwitch.on = self.appDelegate.isConnected;
    [super viewWillAppear:animated];

}

-(void)orientationChanged:(NSNotification *)note {

    NSLog(@"Rotated!");
    CGFloat height = 0.0;

    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    CGFloat mainScreenWidth = mainScreenBounds.size.width;
    CGFloat mainScreenHeight = mainScreenBounds.size.height;
    
    if([self interfaceOrientation] == UIInterfaceOrientationLandscapeLeft ||
       [self interfaceOrientation] == UIInterfaceOrientationLandscapeRight) {
        
        CGFloat temp = mainScreenWidth;
        mainScreenWidth = mainScreenHeight;
        mainScreenHeight = temp;
        
    }

    self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                          self.mainTableView.frame.origin.y,
                                          mainScreenWidth,
                                          mainScreenHeight);
    self.pathView.frame = CGRectMake(self.pathView.frame.origin.x,
                                     self.pathView.frame.origin.y,
                                     mainScreenWidth,
                                     mainScreenHeight);

    if (_helpScroll && _helpView) {

        if (self.view.frame.size.width > self.view.frame.size.height)
            height = self.view.frame.size.width;

        else
            height = self.view.frame.size.height;

        NSLog(@"changing frames.");

        _helpScroll.contentSize = CGSizeMake(_helpScroll.frame.size.width, height + self.navigationController.navigationBar.frame.size.height + self.navigationController.toolbar.frame.size.height);
        [_helpScroll setNeedsDisplay];

    }

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex != 0) {

        static NSString *text = @"";
        static allertTag previousTag = NONE;

        switch (alertView.tag) {

            case ADD_TAG:
                previousTag = ADD_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_TAG] show];
                break;
            case DELETE_TAG:
                //FIXME add code here to delete
                break;
            case MOVE_TAG:
                previousTag = MOVE_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_TAG] show];
                break;
            case RENAME_TAG:
                previousTag = RENAME_TAG;
                text = [alertView textFieldAtIndex:0].text;
                [[self objectInArray:self.alerts WithTag:CONFIRM_TAG] show];
                break;
            case CONFIRM_TAG:
                NSLog(@"Entered= %@", text);
                switch (previousTag) {

                    case ADD_TAG:
                        //FIXME add code here to add a directory
                        break;
                    case MOVE_TAG:
                        //FIXME add code here to move a file/directory
                        break;
                    case RENAME_TAG:
                        //FIXME add code here to rename a file/directory
                        break;
                    default:
                        break;

                }
                previousTag = CONFIRM_TAG;
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

-(void)disPlayHelpPage {
    
    NSString *helpMessagePath = [[NSBundle mainBundle] pathForResource:@"helpPage" ofType:@"txt"];
    NSString *helpMessage = [NSString stringWithContentsOfFile:helpMessagePath encoding:NSUTF8StringEncoding error:NULL];
    
    CGFloat height = 0;
    if (self.view.frame.size.height > self.view.frame.size.width)
        height = self.view.frame.size.height;
    else
        height = self.view.frame.size.width;
    
    _helpView = [[UILabel alloc] initWithFrame:CGRectMake(LARGE_FONT_SIZE,
                                                          0.0,
                                                          self.view.frame.size.width,
                                                          height)];
    _helpView.text = helpMessage;
    _helpView.backgroundColor = [UIColor clearColor];
    _helpView.textColor = [UIColor blackColor];
    _helpView.font = [UIFont systemFontOfSize:MEDIAN_FONT_SIZE];
    _helpView.numberOfLines = 0;
    [_helpView sizeToFit];
    
    _helpScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                 self.view.frame.origin.y + self.navigationController.navigationBar.frame.size.height,
                                                                 self.view.frame.size.width,
                                                                 height - self.navigationController.navigationBar.frame.size.height - self.navigationController.toolbar.frame.size.height)];
    [_helpScroll addSubview:_helpView];
    [_helpScroll setScrollEnabled:YES];
    [_helpScroll setBounces:NO];
    
    _helpScroll.contentSize = CGSizeMake(_helpScroll.frame.size.width, height + self.navigationController.navigationBar.frame.size.height + self.navigationController.toolbar.frame.size.height);
    
    UIViewController *helpController = [[UIViewController alloc] init];
    helpController.title = @"Help Page.";
    [helpController.view addSubview:_helpScroll];
    [self.navigationController pushViewController:helpController animated:YES];
    
}

-(void)displayAddDirPage {

    UIAlertView *addDirAlert = [self objectInArray:self.alerts WithTag:ADD_TAG];
    [addDirAlert show];

}

-(void)buttonPressed:(UIBarButtonItem *)sender {

    //NSLog(@"buttonPressed: %d", sender.tag);
    switch (sender.tag) {

        case HELP_TAG:
            [self disPlayHelpPage];
            break;
        case ADD_DIR_TAG:
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

    return [_fileKeys count];

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
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];

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

    switch (buttonIndex) {

        case 0:
            [[self objectInArray:self.alerts WithTag:MOVE_TAG] show];
            break;
        case 1:
            [[self objectInArray:self.alerts WithTag:RENAME_TAG] show];
            break;
        case 2:
            [[self objectInArray:self.alerts WithTag:DELETE_TAG] show];
            break;
        default:
            break;

    }

}

-(void)displayDetailedViwForItem:(NSDictionary *)dict WithKey:(NSString *)key {

    UIActionSheet *detailSheet = [[UIActionSheet alloc] initWithTitle:@"File/Directory Details"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Move",
                                                                      @"Rename",
                                                                      @"Delete",
                                                                      nil];
    [detailSheet showInView:self.view];

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Fetch data from keys and dictionary
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];

    // if the dict object is a directory then...
    if ([[dict objectForKey:@"isDir"] boolValue]) {

        // set up state for subTableViewController
        NSString *subPath = [NSString stringWithFormat:@"%s%@", _iPadState.currentPath, key];

        // Make subTableviewcontroller to push onto nav stack
        IPadTableViewController *subTableViewController = [[IPadTableViewController alloc] initWithPath:subPath
                                                                                                  target:self.appDelegate
                                                                                            switchAction:self.switchAction
                                                                                               forEvents:_switchEvents];
        subTableViewController.title = key;

        // Set up back button
        [subTableViewController.navigationItem setBackBarButtonItem:[self makeButtonWithTitle:key
                                                                                          Tag:BACK_TAG
                                                                                       Target:nil
                                                                                       Action:nil]];

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
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];

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