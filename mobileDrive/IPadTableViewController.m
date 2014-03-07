//
//  IPadTableViewController.m
//  mobileDrive
//
//  Created by Jesse Scott Pitel on 3/7/14.
//  Copyright (c) 2014 Data Dryvers. All rights reserved.
//

#import "IPadTableViewController.h"

@interface IPadTableViewController ()

@end

@implementation IPadTableViewController {

    NSDictionary *_filesDictionary;
    NSArray *_fileKeys;

}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style {

    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;

}

-(id)initWithDir:(NSString *)cd {

    self = [super init];
    if (self)
        _currentDir = cd;

    return self;

}

-(void)loadView {

    /*CGRect rect = CGRectMake(self.view.superview.frame.origin.x, self.view.superview.frame.origin.y + 20, self.view.superview.frame.size.width, self.view.superview.frame.size.height);*/
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.view = tableView;

}

-(void)buttonPressed:(UIBarButtonItem *)sender {
    
    NSLog(@"buttonPressed: %d", sender.tag);
    
}

- (void)viewDidLoad {

    [super viewDidLoad];

    if(_filesDictionary == nil) {

        NSString *path = [[NSBundle mainBundle] pathForResource:@"files" ofType:@"plist"];
        _filesDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        _fileKeys = [[_filesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];

    }

    UIBarButtonItem *tool = [[UIBarButtonItem alloc] initWithTitle:@"This is a Button"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(buttonPressed:)];
    tool.tag = 1;
    NSArray *toolBarItems = [[NSArray alloc] initWithObjects:tool, nil];
    
    self.toolbarItems = toolBarItems;
    [self.navigationController setToolbarHidden:NO animated:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_fileKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"filesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];
    cell.textLabel.text = key;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.text = [dict objectForKey:@"path"];
    return cell;
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [_fileKeys objectAtIndex:indexPath.row];
    NSDictionary *dict = [_filesDictionary objectForKey:key];
    NSLog(@"tabView didSelectRowAtIndex");
    //push new dictionary with initWithDir: key

}

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
