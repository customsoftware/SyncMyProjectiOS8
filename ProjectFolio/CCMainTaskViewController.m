 //
//  CCMainTaskViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/21/12.
//
//

#import "CCMainTaskViewController.h"
#define TASK_COMPLETE [[NSNumber alloc] initWithInt:1]
#define TASK_ACTIVE [[NSNumber alloc] initWithInt:0]

@interface CCMainTaskViewController ()

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSPredicate *allPredicate;
@property (strong, nonatomic) NSPredicate *incompletePredicate;
@property (strong, nonatomic) NSPredicate *assignedPredicate;
@property (strong, nonatomic) Project *sourceProject;
@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSFetchedResultsController *taskFRC;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) Task *currentTask;
@property (strong, nonatomic) NSIndexPath *selectedPath;
@property (strong, nonatomic) CCTaskViewDetailsController *detailViewController;
@property (strong, nonatomic) CCSubTaskViewController *subTaskController;
@property (strong, nonatomic) CCTaskSummaryViewController *summaryController;
@property BOOL userDrivenDataModelChange;
@property (strong, nonatomic) CCErrorLogger *logger;
@property BOOL  isNew;
@end

@implementation CCMainTaskViewController
@synthesize tableView = _tableView;
@synthesize displayOptions = _displayOptions;
@synthesize context = _context;
@synthesize request = _request;
@synthesize allPredicate = _allPredicate;
@synthesize incompletePredicate = _incompletePredicate;
@synthesize assignedPredicate = _assignedPredicate;
@synthesize sourceProject = _sourceProject;
@synthesize taskFRC = _taskFRC;
@synthesize dateFormatter = _dateFormatter;
@synthesize navButton = _navButton;
@synthesize userDrivenDataModelChange = _userDrivenDataModelChange;
@synthesize currentTask = _currentTask;
@synthesize selectedPath = _selectedPath;
@synthesize detailViewController = _detailViewController;
@synthesize subTaskController = _subTaskController;
@synthesize logger = _logger;
@synthesize isNew = _isNew;


#pragma mark - IBActions/Outlets
-(IBAction)navButton:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == 0) {
        self.tableView.editing = !self.tableView.editing;
        
        if (self.tableView.editing == YES) {
            [self.navButton setTitle:@"Done" forSegmentAtIndex:0];
        } else {
            [self.navButton setTitle:@"Edit" forSegmentAtIndex:0];
        }
        
    } else if ( sender.selectedSegmentIndex == 1 ) {
        [self insertTask];
    }
}

-(Project *)getControllingProject{
    return self.sourceProject;
}

-(void)cancelSummaryChart{
    [self dismissModalViewControllerAnimated:YES];
    self.displayOptions.selectedSegmentIndex = -1;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    // Any config stuff goes here...
}

-(IBAction)insertTask{
    // Show task detail form
    Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:self.context];
    newTask.completed = [NSNumber numberWithBool:NO];
    newTask.taskProject = self.sourceProject;
    newTask.level = [NSNumber numberWithInt:0];
    self.currentTask = newTask;
    self.isNew = YES;
    [self showTaskDetails:self.tableView rowIndex:nil];
}

-(IBAction)displayOptions:(UISegmentedControl *)sender{
    
    if (sender.selectedSegmentIndex == 0 || sender == nil ) {
        [self.taskFRC.fetchRequest setPredicate:self.allPredicate];
    } else if ( sender.selectedSegmentIndex == 1){
        [self.taskFRC.fetchRequest setPredicate:self.assignedPredicate];
    } else if ( sender.selectedSegmentIndex == 2){
        [self.taskFRC.fetchRequest setPredicate:self.incompletePredicate];
    }
    
    [self refreshTableView];
    
}

-(IBAction)cancelPopover{
    [self.context save:nil];
    [self.context deleteObject:self.currentTask];
    [self.taskFRC performFetch:nil];
    [self.tableView reloadData];
    self.currentTask = nil;
    [self.navigationController popViewControllerAnimated:YES];
}


-(BOOL)shouldShowCancelButton{
    return  self.isNew;
}

-(void)savePopoverData{
    if (self.isNew && self.currentTask != nil) {
        self.currentTask.taskProject = self.sourceProject;
        [self.sourceProject addProjectTaskObject:self.currentTask];
        [self.context save:nil];
    }
    
}

-(void)releaseLogger{
    self.logger = nil;
}


-(void)refreshTableView{
    NSError *fetchError = [[NSError alloc] init];
    [self.taskFRC performFetch:&fetchError];
    [self.tableView reloadData];
}

#pragma mark - Life Cycle
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
    self.sourceProject = [self.projectDelegate getActiveProject];
    [self.request setPredicate:self.allPredicate];
    // NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completed" ascending:YES];
    NSSortDescriptor *rowOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: rowOrderDescriptor, nil];
    [self.request setSortDescriptors:sortDescriptors];
    self.taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request
                                                       managedObjectContext:self.context
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    self.taskFRC.delegate = self;
    
    NSString *addTaskNotification = [[NSString alloc] initWithFormat:@"%@", @"newTaskNotification"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:addTaskNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.sourceProject = [self.projectDelegate getActiveProject];
    if (self.displayOptions.selectedSegmentIndex == 3 || self.displayOptions.selectedSegmentIndex == -1) {
        [self displayOptions:nil];
    } else {
        [self displayOptions:self.displayOptions];
    }
    NSMutableArray *things = [[self.taskFRC fetchedObjects] mutableCopy];
    [self reSortSubTasksWithTasks:things];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.allPredicate = nil;
    self.incompletePredicate = nil;
    self.assignedPredicate = nil;
}

-(void)viewDidUnload{
    self.tableView = nil;
    self.displayOptions = nil;
    self.context = nil;
    self.taskFRC = nil;
    self.request = nil;
    self.allPredicate = nil;
    self.incompletePredicate = nil;
    self.assignedPredicate = nil;
    self.dateFormatter = nil;
    self.currentTask = nil;
    self.selectedPath = nil;
    self.navButton = nil;
    self.currentTask = nil;
    self.detailViewController = nil;
    self.logger = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table Support
-(void)showTaskDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    self.detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskDetails"];
    self.detailViewController.activeTask = self.currentTask;
    self.selectedPath = indexPath;
    self.detailViewController.taskDelegate = self;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

-(void)deleteTaskAtIndexPath:(NSIndexPath *)indexPath{
    self.taskFRC.delegate = nil;
    if (indexPath != nil) {
        self.currentTask = [self.taskFRC objectAtIndexPath:indexPath];
    }
    
        // Free the child tasks.. move them all up one level
        int taskLevel = [self.currentTask.level integerValue];
        for (Task * subTask in self.currentTask.subTasks) {
            [subTask setLevelWith:[NSNumber numberWithInt:taskLevel]];
            subTask.superTask = nil;
            subTask.visible = [NSNumber numberWithBool:YES];
        }
        [self.context deleteObject:self.currentTask];

    NSError *fetchError = nil;
    @try {
        if (![self.taskFRC performFetch:&fetchError]){
            self.logger = [[CCErrorLogger alloc] initWithError:fetchError andDelegate:self];
            [self.logger releaseLogger];
        } else {
            [self.tableView reloadData];
        }
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:fetchError andDelegate:self];
        [self.logger releaseLogger];
    }
    self.taskFRC.delegate = self;
}

#pragma mark - Table Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.taskFRC.fetchedObjects count];
}

-(void)configureCell:(UITableViewCell *)cell forTask:(Task * )taskItem{
    static NSString *CollapsedParentIdentifier = @"groupCell";
    static NSString *CollapsedLateParentIdentifier = @"lateParentCell";
    cell.indentationLevel = [taskItem.level integerValue];
    cell.indentationWidth = 10.0f;
    NSString *detailMessage;
    NSString *ownerName;
    if (taskItem.assignedTo == nil) {
        ownerName = @"Self";
    } else {
        ownerName = [[NSString alloc] initWithFormat:@"%@ %@", taskItem.assignedFirst, taskItem.assignedLast];
    }
    
    cell.textLabel.text = taskItem.title;
    cell.detailTextLabel.text = detailMessage;

    cell.textLabel.textColor = [UIColor blackColor];

    if (taskItem.virtualComplete == TASK_COMPLETE) {
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.textColor = [UIColor colorWithHue:0.333 saturation:.8 brightness:.539 alpha:1];
    } else if ([taskItem.isOverDue boolValue]) {
        cell.detailTextLabel.textColor = [UIColor redColor];
    } else {
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    if (cell.reuseIdentifier == CollapsedParentIdentifier) {
        if ([taskItem isExpanded]) {
            cell.imageView.image = [UIImage imageNamed:@"Expanded.png"];
            if (taskItem.dueDate == nil) {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
            } else {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:taskItem.dueDate]];
            }
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Collapsed.png"];
            NSDate *earliestDate = [taskItem earliestDate];
            if ( earliestDate == nil) {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
            } else {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:earliestDate]];
            }
        }
        cell.detailTextLabel.text = detailMessage;
    } else if (cell.reuseIdentifier == CollapsedLateParentIdentifier) {
        if ([taskItem isExpanded]) {
            cell.imageView.image = [UIImage imageNamed:@"Expanded.png"];
            if (taskItem.dueDate == nil) {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
            } else {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:taskItem.dueDate]];
            }
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Collapsed.png"];
            NSDate *earliestDate = [taskItem earliestDate];
            if ( earliestDate == nil) {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
            } else {
                detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:earliestDate]];
            }
        }
        cell.detailTextLabel.text = detailMessage;
    } else {
        if (taskItem.dueDate == nil) {
            detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@", ownerName];
        } else {
            detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:taskItem.dueDate]];
        }
        cell.imageView.image = nil;
        cell.detailTextLabel.text = detailMessage;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Task *task = [self.taskFRC objectAtIndexPath:indexPath];
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
-(void)persistentStoreDidChange{
    NSError *error =  nil;
    [self.taskFRC performFetch:&error];
    [self.tableView reloadData];
}

-(void)reSortSubTasksWithTasks:(NSMutableArray *)taskList{
    double i = 0;
    for (Task *task in taskList)
    {
        i = i + 1;
        if (task.superTask == nil) {
            // The super task is after this...
            task.displayOrder = [NSNumber numberWithDouble:i];
            // NSLog(@"%f", i);
            NSNumber * newOrder = [NSNumber numberWithDouble:i];
            newOrder = [task setNewDisplayOrderWith:newOrder];
            i = [newOrder doubleValue];
        }
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.currentTask = [self.taskFRC objectAtIndexPath:indexPath];
    self.isNew = NO;
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
        [self deleteTaskAtIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL retValue = YES;
    // The table view should not be re-orderable.
    Task *selectedTask = [self.taskFRC objectAtIndexPath:indexPath];
    if (selectedTask.completed == TASK_COMPLETE) {
        retValue = NO;
    } else if (selectedTask.superTask != nil){
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
    
    [self reSortSubTasksWithTasks:things];
    
    NSError *error = [[NSError alloc] init];
    if (![self.context save:&error]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Core Data Error" message:@"The save failed your data didn't persist" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self.taskFRC performFetch:nil];
    [self.tableView reloadData];
    self.userDrivenDataModelChange = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentTask = [self.taskFRC objectAtIndexPath:indexPath];
    // Update the detail view contents
    if (self.currentTask.subTasks != nil && [self.currentTask.subTasks count] > 0) {
        // What we do here is make the sub
        if ([self.currentTask isExpanded] == YES) {
            for (Task *subTask in self.currentTask.subTasks) {
                [subTask setSubTaskVisible:[NSNumber numberWithBool:NO]];
            }
        } else {
            for (Task *subTask in self.currentTask.subTasks) {
                [subTask setSubTaskVisible:[NSNumber numberWithBool:YES]];
            }
        }
        [self.taskFRC performFetch:nil];
        [self.tableView reloadData];
    } else {
        self.isNew = NO;
        [self showTaskDetails:self.tableView rowIndex:indexPath];
    }
}

#pragma mark - Lazy Getters
-(NSManagedObjectContext *)context{
    if (_context == nil) {
        // CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        CoreData *sharedModel = [CoreData sharedModel:self];
        _context = sharedModel.managedObjectContext;
    }
    return _context;
}

-(NSFetchRequest *)request{
    if (_request == nil) {
        _request = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    }
    return _request;
}

-(NSPredicate *)allPredicate{
    if (_allPredicate == nil) {
        NSString *filterProject = self.sourceProject.projectName;
        _allPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@ AND visible == YES", filterProject];
    }
    return _allPredicate;
}

-(NSPredicate *)assignedPredicate {
    if (_assignedPredicate == nil) {
        NSString *filterProject = self.sourceProject.projectName;
        _assignedPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@ AND assignedTo != nil AND visible == YES", filterProject];
    }
    return _assignedPredicate;
}

-(NSPredicate *)incompletePredicate{
    if (_incompletePredicate == nil) {
        NSString *filterProject = self.sourceProject.projectName;
        _incompletePredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@ AND completed == 0 AND visible == YES", filterProject];
    }
    return _incompletePredicate;
}

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
