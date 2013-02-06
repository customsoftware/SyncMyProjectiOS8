//
//  CCProjectSwitchTableViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/5/12.
//
//

#import "CCProjectSwitchTableViewController.h"

@interface CCProjectSwitchTableViewController ()

@end

@implementation CCProjectSwitchTableViewController
@synthesize fetchRequest = _fetchRequest;
@synthesize projectFRC = _projectFRC;
@synthesize selectedProject = _selectedProject;
@synthesize currentTimer = _currentTimer;

#pragma mark - View Lifecycle

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

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *projectNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"projectName" ascending:YES];
    NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: projectNameDescriptor, completeDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.projectFRC.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.projectFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    
    NSError *requestError = nil;
    if ([self.projectFRC performFetch:&requestError]) {
        [self.tableView reloadData];
    }
    NSUInteger rowPointer = -1;
    for (Project *project in [self.projectFRC fetchedObjects]) {
        if ([self.selectedProject.projectName isEqualToString:project.projectName]) {
            rowPointer = [[self.projectFRC fetchedObjects] indexOfObject:project];
            break;
        }
    }
    NSIndexPath *projectIndex = [NSIndexPath indexPathForRow:rowPointer inSection:0];
    [self.tableView selectRowAtIndexPath:projectIndex animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.fetchRequest = nil;
    self.projectFRC = nil;
    self.selectedProject = nil;
    self.currentTimer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.projectFRC sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.projectFRC sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"projectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    cell.textLabel.text = [[self.projectFRC objectAtIndexPath:indexPath] projectName];
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
    if (indexPath != nil) {
        Project *newProject = [self.projectFRC objectAtIndexPath:indexPath];
        if (![self.selectedProject.projectName isEqualToString:newProject.projectName]){
            WorkTime *transferedEvent = [NSEntityDescription insertNewObjectForEntityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            
            if (transferedEvent != nil && [[CoreData sharedModel:nil] managedObjectContext] != nil) {
                transferedEvent.billed = self.currentTimer.billed;
                transferedEvent.start = self.currentTimer.start;
                transferedEvent.end = self.currentTimer.end;
                transferedEvent.workProject = newProject;
                
                [self.selectedProject removeProjectWorkObject:self.currentTimer];
                
                if (newProject != nil && transferedEvent != nil) {
                    [newProject addProjectWorkObject:transferedEvent];
                }
            }
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}


@end
