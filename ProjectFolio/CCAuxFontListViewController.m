//
//  CCAuxFontListViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import "CCAuxFontListViewController.h"
#define kFontNameKey @"font"

@interface CCAuxFontListViewController ()
@property (assign, nonatomic) CCMasterViewController *mainController;

@end

@implementation CCAuxFontListViewController
@synthesize orderedFonts = _orderedFonts;
@synthesize mainController = _mainController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.orderedFonts = [[UIFont familyNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated{
    // Find the selected font from settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger rowPointer = -1;
    NSString *fontName = [userDefaults objectForKey:kFontNameKey];
    // Find the place in the array
    for (NSString *font in self.orderedFonts){
        if ([font isEqualToString:fontName]) {
            rowPointer = [self.orderedFonts indexOfObject:font];
            break;
        }
    }
    // Select that row
    NSIndexPath *fontIndex = [NSIndexPath indexPathForRow:rowPointer inSection:0];
    [self.tableView selectRowAtIndexPath:fontIndex animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.mainController = nil;
    self.orderedFonts = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.orderedFonts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"fontCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [self.orderedFonts objectAtIndex:[indexPath row]];
    cell.textLabel.font = [UIFont fontWithName:cell.textLabel.text size:18.0f];
    //cell.detailTextLabel.text = [[NSString alloc]
    //                             initWithFormat:@"Number of font faces: %d", [[UIFont fontNamesForFamilyName:cell.textLabel.text] count]];
    return cell;
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Put the selected font into the settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[self.orderedFonts objectAtIndex:indexPath.row] forKey:kFontNameKey];
    
    // Send a notification out which the detail controller is listening for...
    NSString *fontChangeNotification = @"FontChangeNotification";
    
    NSNotification *fontChange = [NSNotification notificationWithName:fontChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:fontChange];
    
    //[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Lazy Getter
-(CCMasterViewController *)mainController{
    if (_mainController == nil) {
        CCAppDelegate *appDelegate = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
        UISplitViewController *svc = (UISplitViewController *)appDelegate.window.rootViewController;
        UINavigationController *nc = [svc.viewControllers objectAtIndex:0];
        _mainController = (CCMasterViewController *)nc.topViewController;
    }
    return _mainController;
}

@end
