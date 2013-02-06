//
//  CCTaskViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/1/12.
//
//

#import "CCTaskViewController.h"
#define TASK_COMPLETE [[NSNumber alloc] initWithInt:1]
#define TASK_ACTIVE [[NSNumber alloc] initWithInt:0]


@interface CCTaskViewController ()
@property CGRect currentImageFrame;
@property BOOL userDrivenDataModelChange;
@end

@implementation CCTaskViewController

@synthesize project = _project;
@synthesize task = _task;
@synthesize childController = _childController;
@synthesize dateFormatter = _dateFormatter;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchRequest = _fetchRequest;
@synthesize taskFRC = _taskFRC;
@synthesize summaryController = _summaryController;
@synthesize currentImageFrame = _currentImageFrame;
@synthesize userDrivenDataModelChange = _userDrivenDataModelChange;

#pragma mark - IBActions
-(IBAction)clickSummary:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == 0) {
        // Show summary of expenses
        CGRect rect = self.view.frame;
        self.summaryController.contentSizeForViewInPopover = rect.size;
        [self.navigationController pushViewController:self.summaryController animated:YES];
    } else {
        // Bill all unbilled expenses
        //  Sending the email will bill all of them
    }
}

-(IBAction)cancelPopover{
    [self deletTaskAtInidexPath:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)savePopoverData{
    
}

-(BOOL)shouldShowCancelButton{
    BOOL retValue = NO;
    if (self.childController.selectedIndexPath == nil) {
        retValue = YES;
    }
    return  retValue;
}

-(IBAction)insertTask{
    // Show task detail form
    Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
    if (newTask != nil) {
        newTask.title = @"New Task";
        newTask.completed = [[NSNumber alloc] initWithInt:0];
        newTask.taskProject = self.project;

        [self.project addProjectTaskObject:newTask];
        self.task = newTask;
        
        [self showTaskDetails:self.tableView rowIndex:nil];
    } else {
        NSLog(@"Failed to create new task");
    }
}

-(void)showTaskDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    self.childController.activeTask = self.task;
    CGRect rect = self.view.frame;
    self.childController.contentSizeForViewInPopover = rect.size;
    self.childController.selectedIndexPath = indexPath;
    self.childController.taskDelegate = self;
    [self.navigationController pushViewController:self.childController animated:YES];
}

#pragma mark - View Lifecycle

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
	// Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
    // NSSortDescriptor *dueWhenDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:YES];
    NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completed" ascending:YES];
    NSSortDescriptor *rowOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    // CCNullSortDescriptor *nullDescriptor = [[CCNullSortDescriptor alloc] initWithKey:@"dueDate" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: completeDescriptor, rowOrderDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.taskFRC.delegate = self;

}

-(void)viewWillAppear:(BOOL)animated{
    NSString *filterProject = self.project.projectName;
    NSPredicate *completedPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@", filterProject];
    [self.fetchRequest setPredicate:completedPredicate];
    
    self.taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:self.managedObjectContext
                                                         sectionNameKeyPath:nil
                                                                  cacheName:@"taskListCache"];
    
    NSError *requestError = nil;
    if ([self.taskFRC performFetch:&requestError]) {
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    self.project = nil;
    self.task = nil;
    self.childController = nil;
    self.dateFormatter = nil;
    self.managedObjectContext = nil;
    self.taskFRC = nil;
    self.summaryController = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - Table View tasks

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.taskFRC sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.taskFRC sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *lateCellIdentifier = @"lateDetails";
    static NSString *CellIdentifier = @"taskDetails";
    UITableViewCell *returnCell = nil;
    self.task = [self.taskFRC objectAtIndexPath:indexPath];
    NSTimeInterval dateComparisonResult;
    
    if (self.task.dueDate != nil) {
        dateComparisonResult = [[NSDate date] timeIntervalSinceDate:self.task.dueDate];
    }
    
    if (self.task.dueDate != nil && dateComparisonResult > 0 && self.task.completed == TASK_ACTIVE) {
        UITableViewCell *lateCell = [tableView dequeueReusableCellWithIdentifier:lateCellIdentifier];
        if (lateCell == nil) {
            lateCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:lateCellIdentifier];
        }
        returnCell = lateCell;
    } else {
        UITableViewCell *onTimeCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (onTimeCell == nil) {
            onTimeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        returnCell = onTimeCell;
    }
    
    [self configureCell:returnCell];
    return returnCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self deletTaskAtInidexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL retValue = YES;
    // The table view should not be re-orderable.
    Task *selectedTask = [self.taskFRC objectAtIndexPath:indexPath];
    if (selectedTask.completed == TASK_COMPLETE) {
        retValue = NO;
    }
    return retValue;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    self.userDrivenDataModelChange = YES;
    NSMutableArray *things = [[self.taskFRC fetchedObjects] mutableCopy];
    
    // Grab the item we're moving.
    Task *task = [self.taskFRC objectAtIndexPath:sourceIndexPath];
    
    // Remove the object we're moving from the array.
    [things removeObject:task];
    // Now re-insert it at the destination.
    [things insertObject:task atIndex:[destinationIndexPath row]];
    
    // All of the objects are now in their correct order. Update each
    // object's displayOrder field by iterating through the array.
    int i = 0;
    for (Task *task in things)
    {
        [task setValue:[NSNumber numberWithInt:i++] forKey:@"displayOrder"];
    }
    
    [self.managedObjectContext save:nil];
    self.userDrivenDataModelChange = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
    self.task = [self.taskFRC objectAtIndexPath:indexPath];
    [self showTaskDetails:self.tableView rowIndex:indexPath];    
}

-(void)configureCell:(UITableViewCell *)cell{
    
    NSString *detailMessage;
    NSString *ownerName;
    if (self.task.assignedTo == nil) {
        ownerName = @"Self";
    } else {
        ownerName = [[NSString alloc] initWithFormat:@"%@ %@", self.task.assignedFirst, self.task.assignedLast];
    }
    
    if (self.task.dueDate == nil) {
        detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
    } else {
        detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:self.task.dueDate]];
    }
    cell.indentationWidth = 10.0f;
    if ([self.task.parentTask integerValue] > 0) {
        NSLog(@"Here we set indent level for task: %@ which has %d for a parent task", self.task.title, [self.task.parentTask integerValue]);
        cell.indentationLevel = 1;
    } else {
        cell.indentationLevel = 0;
    }
    
    cell.textLabel.text = self.task.title;
    cell.detailTextLabel.text = detailMessage;
    if (self.task.completed == TASK_COMPLETE) {
        cell.imageView.image = [UIImage imageNamed:@"checkmark-box-small-green.png"];
        cell.detailTextLabel.text = nil;
    } else {
        cell.imageView.image = nil;
    }
}

-(void)deletTaskAtInidexPath:(NSIndexPath *)indexPath{
    self.taskFRC.delegate = nil;
    if (indexPath == nil) {
        // We have to find it based upon deliverable which is already set in this instance
        indexPath = [self.taskFRC indexPathForObject:self.task];
    } else {
        self.task = [self.taskFRC objectAtIndexPath:indexPath];
    }
    [self.managedObjectContext deleteObject:self.task];
    //if ([self.deliverable isDeleted]) { // This caused some inconsistent results. Leaving it commented out, but present
    NSError *savingError = nil;
    if ([self.managedObjectContext save:&savingError]) {
        NSError *fetchError = nil;
        if ([self.taskFRC performFetch:&fetchError]) {
            if (indexPath != nil) {
                NSArray *rowsToDelete = [[NSArray alloc] initWithObjects:indexPath, nil];
                [self.tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    } else {
        NSLog(@"Saving the delete failed: %@", savingError);
    }
    //}
    self.taskFRC.delegate = self;
}


#pragma mark - Lazy Getters

-(CCTaskViewDetailsController *)childController{
    if (_childController == nil) {
        _childController = [[CCTaskViewDetailsController alloc] initWithNibName:@"CCTaskViewDetailsController" bundle:nil];
    }
    return _childController;
}

-(CCTaskSummaryViewController *)summaryController{
    if (_summaryController == nil) {
        _summaryController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskSummary"];
    }
    return _summaryController;
}

-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

-(NSManagedObjectContext *)managedObjectContext{
    if (_managedObjectContext == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = application.managedObjectContext;
        
    }
    return _managedObjectContext;
}


@end
