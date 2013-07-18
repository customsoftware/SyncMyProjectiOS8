//
//  CCSubTaskViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/27/12.
//
//

#import "CCSubTaskViewController.h"
#define TASK_COMPLETE [[NSNumber alloc] initWithInt:1]
#define TASK_ACTIVE [[NSNumber alloc] initWithInt:0]

@interface CCSubTaskViewController ()
@property (strong, nonatomic) Project *sourceProject;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) Task *currentTask;
@property (strong, nonatomic) NSIndexPath *selectedPath;
@property (strong, nonatomic) CCTaskViewDetailsController *detailViewController;
@property (strong, nonatomic) CCSubTaskViewController *subTaskController;
@property BOOL userDrivenDataModelChange;

@end

@implementation CCSubTaskViewController
@synthesize tableView = _tableView;
@synthesize sourceProject = _sourceProject;
@synthesize dateFormatter = _dateFormatter;
@synthesize userDrivenDataModelChange = _userDrivenDataModelChange;
@synthesize currentTask = _currentTask;
@synthesize selectedPath = _selectedPath;
@synthesize detailViewController = _detailViewController;
@synthesize controllingTask = _controllingTask;

# pragma mark - Life Cycle
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
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title = self.controllingTask.title;
    [self.tableView reloadData];
}

-(void)viewDidUnload{
    self.tableView = nil;
    self.dateFormatter = nil;
    self.currentTask = nil;
    self.selectedPath = nil;
    self.currentTask = nil;
    self.detailViewController = nil;
    self.subTaskController = nil;
    self.controllingTask = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - IBOutlet/IBAction
-(IBAction)editButton:(UIBarButtonItem *)sender{
    
   self.tableView.editing = !self.tableView.editing;
   if (self.tableView.editing == YES) {
        [self.editButton setTitle:@"Done"];
    } else {
        [self.editButton setTitle:@"Edit"];
    }
 
}

-(IBAction)cancelPopover{
    [self deleteTaskAtInidexPath:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)savePopoverData{
    
}


-(BOOL)shouldShowCancelButton{
    BOOL retValue = NO;
    return  retValue;
}


#pragma mark - Table Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.controllingTask.subTasks count];
}

-(void)configureCell:(UITableViewCell *)cell forTask:(Task * )taskItem{
    static NSString *CollapsedParentIdentifier = @"groupCell";
    static NSString *CollapsedLateParentIdentifier = @"lateParentCell";
    NSString *detailMessage;
    NSString *ownerName;
    if (taskItem.assignedTo == nil) {
        ownerName = @"Self";
    } else {
        ownerName = [[NSString alloc] initWithFormat:@"%@ %@", taskItem.assignedFirst, taskItem.assignedLast];
    }
    
    if (taskItem.dueDate == nil) {
        detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
    } else {
        detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:taskItem.dueDate]];
    }
    
    cell.textLabel.text = taskItem.title;
    cell.detailTextLabel.text = detailMessage;
    if (taskItem.completed == TASK_COMPLETE) {
        cell.imageView.image = [UIImage imageNamed:@"checkmark-box-small-green.png"];
        cell.detailTextLabel.text = nil;
    } else {
        if (cell.reuseIdentifier == CollapsedParentIdentifier) {
            cell.imageView.image = [UIImage imageNamed:@"15-tags.png"];
        } else if (cell.reuseIdentifier == CollapsedLateParentIdentifier) {
            cell.imageView.image = [UIImage imageNamed:@"15-tags.png"];
        } else {
            cell.imageView.image = nil;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int selectCell = indexPath.row;
    if (selectCell > self.controllingTask.subTasks.count - 1) {
        NSLog(@"We are going to crash: tableViewCell");
    }
    
    Task *task = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
    static NSString *CollapsedParentIdentifier = @"groupCell";
    static NSString *ChildIdentifier = @"childCellOnTime";
    static NSString *CollapsedLateParentIdentifier = @"lateParentCell";
    static NSString *LateChildIdentifier = @"childCellLate";
    UITableViewCell *cell = nil;
    
    if ([task.subTasks count] > 0) {
        if ([task.isOverDue boolValue] ) {
            cell = [tableView dequeueReusableCellWithIdentifier:CollapsedLateParentIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CollapsedLateParentIdentifier];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:CollapsedParentIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CollapsedParentIdentifier];
            }
        }
    } else {
        if ( [task.isOverDue boolValue] ) {
            cell = [tableView dequeueReusableCellWithIdentifier:LateChildIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:LateChildIdentifier];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:ChildIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ChildIdentifier];
            }
        }
    }
    
    // Configure the cell...
    [self configureCell:cell forTask:task];
    
    return cell;
}

#pragma mark - Table Delegate
-(void)showTaskDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    self.detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskDetails"];
    self.detailViewController.activeTask = self.currentTask;
    self.selectedPath = indexPath;
    self.detailViewController.taskDelegate = self;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

-(void)deleteTaskAtInidexPath:(NSIndexPath *)indexPath{
    Task *task = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
    [self.controllingTask removeSubTasksObject:task];
}


-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.currentTask = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
    [self showTaskDetails:self.tableView rowIndex:indexPath];
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
        [self deleteTaskAtInidexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL retValue = YES;
    // The table view should not be re-orderable.
    Task *selectedTask = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
    if (selectedTask.completed == TASK_COMPLETE) {
        retValue = NO;
    }
    return retValue;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    self.userDrivenDataModelChange = YES;
    NSMutableOrderedSet *things = [[NSMutableOrderedSet alloc] initWithArray: [self.controllingTask.subTasks allObjects]];
    
    // Grab the item we're moving.
    Task *task = [[self.controllingTask.subTasks allObjects] objectAtIndex:sourceIndexPath.row];
    
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
    
    [self.controllingTask addSubTasks:[[NSSet alloc] initWithArray:[things array]]];
    [self.tableView reloadData];
    self.userDrivenDataModelChange = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
    self.currentTask = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
    if (self.currentTask.subTasks != nil && [self.currentTask.subTasks count] > 0) {
        self.subTaskController.controllingTask = [[self.controllingTask.subTasks allObjects] objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:self.subTaskController animated:YES];
    } else {
        [self showTaskDetails:self.tableView rowIndex:indexPath];
    }
}

#pragma mark - Lazy Getters
-(NSDateFormatter *)dateFormatter{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
    return _dateFormatter;
}

-(CCSubTaskViewController *)subTaskController{
    if (_subTaskController == nil) {
        _subTaskController = [self.storyboard instantiateViewControllerWithIdentifier:@"subTaskView"];
    }
    return _subTaskController;
}

@end
