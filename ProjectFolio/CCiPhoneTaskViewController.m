//
//  CCiPhoneTaskViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 11/28/12.
//
//

#import "CCiPhoneTaskViewController.h"
#import "CCiPhoneDetailViewController.h"

#define TASK_COMPLETE [[NSNumber alloc] initWithInt:1]
#define TASK_ACTIVE [[NSNumber alloc] initWithInt:0]
#define kStartNotification @"ProjectTimerStartNotification"
#define kStartTaskNotification @"TaskTimerStartNotification"
#define kStopNotification @"ProjectTimerStopNotification"

@interface CCiPhoneTaskViewController () <CCNotesDelegate>

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
@property (strong, nonatomic) CCiPhoneDetailViewController *detailController;
@property BOOL userDrivenDataModelChange;
@property (strong, nonatomic) CCErrorLogger *logger;
@property BOOL  isNew;
@property NSInteger lastSegment;
@property (strong, nonatomic) UIToolbar *holderBar;
@property (strong, nonatomic) CCExpenseNotesViewController *notesController;

- (IBAction)toggleEditMode:(UIButton *)sender;
- (IBAction)insertTask:(UIButton *)sender;

@end

@implementation CCiPhoneTaskViewController

#pragma mark - IBActions/Outlets

-(Project *)getControllingProject{
    return self.sourceProject;
}

-(void)cancelSummaryChart{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.displayOptions.selectedSegmentIndex = -1;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    // Any config stuff goes here...
}

- (IBAction)toggleEditMode:(UIButton *)sender
{
    self.tableView.editing = !self.tableView.editing;
    
    if (self.tableView.editing) {
        [sender setTitle:@"Done" forState:UIControlStateNormal];
    } else {
        [sender setTitle:@"Edit" forState:UIControlStateNormal];
    }
}

-(IBAction)insertTask:(UIButton *)sender{
    // Show task detail form
    Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newTask.completed = [NSNumber numberWithBool:NO];
    newTask.taskProject = self.sourceProject;
    newTask.level = [NSNumber numberWithInt:0];
    self.currentTask = newTask;
    self.isNew = YES;
    [self showTaskDetails:self.tableView rowIndex:nil];
}

- (IBAction)goToNotes:(UIBarButtonItem *)sender {
    self.detailController.project = self.sourceProject;
    [self.navigationController pushViewController:self.detailController animated:YES];

}

-(IBAction)displayOptions:(UISegmentedControl *)sender{
    
    if (sender.selectedSegmentIndex == 0 || sender == nil ) {
        [self.taskFRC.fetchRequest setPredicate:self.allPredicate];
    } else if ( sender.selectedSegmentIndex == 1){
        [self.taskFRC.fetchRequest setPredicate:self.assignedPredicate];
    } else if ( sender.selectedSegmentIndex == 2){
        [self.taskFRC.fetchRequest setPredicate:self.incompletePredicate];
    }
    if (sender.selectedSegmentIndex == 3) {
        self.detailController.project = [self.projectDelegate getActiveProject];
        [self.navigationController pushViewController:self.detailController animated:YES];
        sender.selectedSegmentIndex = -1;
    } else {
        [self refreshTableView];
        self.lastSegment = sender.selectedSegmentIndex;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:kTaskFilterStatus];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)cancelPopover{
    [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.currentTask];
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
        [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
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
    NSSortDescriptor *nameOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: rowOrderDescriptor, nameOrderDescriptor,nil];
    [self.request setSortDescriptors:sortDescriptors];
    self.taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request
                                                       managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    self.taskFRC.delegate = self;
    
    NSString *addTaskNotification = [[NSString alloc] initWithFormat:@"%@", @"newTaskNotification"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:addTaskNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:kiCloudSyncNotification object:nil];
    
    // Add long press to show/hide sub-tasks
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(toggleDisplayOfChildren:)];
    [self.tableView addGestureRecognizer:longPress];
    
    longPress.numberOfTouchesRequired = 1;
    longPress.minimumPressDuration = kLongPressDuration;
    
    // Add swipe to show notes
    UISwipeGestureRecognizer *showExtrasSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    showExtrasSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:showExtrasSwipe];
    
    // Add swipe to add records
    self.swiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(insertTask:)];
    [self.swiper setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.navigationController.navigationBar addGestureRecognizer:self.swiper];
    
    self.displayOptions.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kTaskFilterStatus];
    self.lastSegment = [[NSUserDefaults standardUserDefaults] integerForKey:kTaskFilterStatus];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.sourceProject = [self.projectDelegate getActiveProject];
    if (self.displayOptions.selectedSegmentIndex == -1) {
        self.displayOptions.selectedSegmentIndex = self.lastSegment;
    }
    [self displayOptions:self.displayOptions];
    self.swiper.enabled = YES;
    NSMutableArray *things = [[self.taskFRC fetchedObjects] mutableCopy];
    [self reSortSubTasksWithTasks:things];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.sourceProject) {
        [self.sourceProject.managedObjectContext save:nil];
    }
    self.allPredicate = nil;
    self.incompletePredicate = nil;
    self.assignedPredicate = nil;
    self.swiper.enabled = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <CCNotesDeleage>
-(void)releaseNotes {
    self.currentTask.notes = self.notesController.notes.text;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSString *)getNotes {
    return self.currentTask.notes;
}

-(BOOL)isTaskClass{
    return YES;
}

-(Task *)getParentTask {
    return self.currentTask;
}

#pragma mark - Helpers
- (void)toggleDisplayOfChildren:(UILongPressGestureRecognizer *)longPress {
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:swipedIndexPath];
    self.currentTask = [self.taskFRC objectAtIndexPath:swipedIndexPath];
    
    if (UIGestureRecognizerStateEnded == longPress.state) {
        cell.highlighted = NO;
    } else if (UIGestureRecognizerStateBegan == longPress.state) {
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
            [self.taskFRC.managedObjectContext save:nil];
            [self.taskFRC performFetch:nil];
            [self.tableView reloadData];
        } else {
            self.isNew = NO;
        }
        cell.highlighted = YES;
    } else if (UIGestureRecognizerStateRecognized == longPress.state) {
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
            [self.taskFRC.managedObjectContext save:nil];
            [self.taskFRC performFetch:nil];
            [self.tableView reloadData];
        } else {
            self.isNew = NO;
        }
        cell.highlighted = YES;
    }
}

- (void)swipeRight:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
    self.currentTask = [self.taskFRC objectAtIndexPath:swipedIndexPath];
    if (self.currentTask) {
        // Show notes here
        self.notesController = [self.storyboard instantiateViewControllerWithIdentifier:@"expenseNotes"];
        self.notesController.modalPresentationStyle = UIModalPresentationFormSheet;
        self.notesController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        self.notesController.notesDelegate = self;
        [self presentViewController:self.notesController animated:YES completion:nil];
    }
}

-(void)sendTimerStartNotificationForTask{
    NSDictionary *projectDictionary = @{ @"Project" :self.currentTask.taskProject,
                                         @"Task" : self.currentTask };
    NSNotification *startTimer = [NSNotification notificationWithName:kStartTaskNotification object:nil userInfo:projectDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:startTimer];
}

-(void)sendTimerStartNotificationForProject{
    NSDictionary *projectDictionary = @{ @"Project" : self.currentTask.taskProject };
    [[NSNotificationCenter defaultCenter] postNotificationName:kStartNotification object:nil userInfo:projectDictionary];
}

-(void)sendTimerStopNotification{
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
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
    int taskLevel = [self.currentTask.level intValue];
    for (Task * subTask in self.currentTask.subTasks) {
        [subTask setLevelWith:[NSNumber numberWithInt:taskLevel]];
        subTask.superTask = nil;
        subTask.visible = [NSNumber numberWithBool:YES];
    }
    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.currentTask];
    
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
            if (taskItem.virtualComplete == TASK_COMPLETE) {
                cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
                cell.detailTextLabel.textColor = kGreenColor;
            } else {
                cell.imageView.image = [UIImage imageNamed:@"Expanded.png"];
            }
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
            if (taskItem.virtualComplete == TASK_COMPLETE) {
                cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
                cell.detailTextLabel.textColor = kGreenColor;
            } else {
                cell.imageView.image = [UIImage imageNamed:@"Expanded.png"];
            }
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
        if (taskItem.virtualComplete == TASK_COMPLETE) {
            cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
            cell.detailTextLabel.textColor = kGreenColor;
        } else if (taskItem.notes.length > 0) {
            cell.imageView.image = [UIImage imageNamed:@"179-notepad.png"];
        } else {
            cell.imageView.image = nil;
        }
        cell.detailTextLabel.text = detailMessage;
    }
    
    UIColor *taskColor = [taskItem.taskPriority getCategoryColor];
    if (!taskColor) taskColor = [UIColor whiteColor];
    UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 44)];
    catColor.backgroundColor = taskColor;
    catColor.layer.cornerRadius = 0;
    catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    catColor.layer.borderWidth = .5;
    [cell addSubview:catColor];
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
    if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Core Data Error" message:@"The save failed your data didn't persist" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self.taskFRC performFetch:nil];
    [self.tableView reloadData];
    self.userDrivenDataModelChange = NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentTask) [self.currentTask.managedObjectContext save:nil];    
    self.currentTask = [self.taskFRC objectAtIndexPath:indexPath];
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForTask];
    self.isNew = NO;
    [self showTaskDetails:self.tableView rowIndex:indexPath];
}

#pragma mark - Lazy Getters
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

-(CCiPhoneDetailViewController *)detailController{
    if (_detailController == nil) {
        _detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"detailViewController"];
    }
    return _detailController;
}

@end
