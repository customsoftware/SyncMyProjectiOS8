//
//  CCParentTaskViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/10/12.
//
//

#import "CCParentTaskViewController.h"

@interface CCParentTaskViewController ()

@property (strong, nonatomic) NSFetchedResultsController * taskFRC;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *displayList;
@end

@implementation CCParentTaskViewController
@synthesize popDelegate = _popDelegate;
@synthesize taskFRC = _taskFRC;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchRequest = _fetchRequest;
@synthesize parentTask = _parentTask;
@synthesize activeTask = _activeTask;
@synthesize displayList = _displayList;

#pragma mark - Support
-(void)cancelParent{
    [self.popDelegate cancelParent];
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSMutableArray *)removeIneligibleRecordsFrom:(NSMutableArray *)taskList{
    // We remove any records which are in the downline of the controlling task
    taskList = [self.activeTask removeSubTasksFromArray:taskList basedUponTask:self.activeTask];
    return taskList;
}

#pragma mark - Life Cycle
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
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(cancelParent)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *taskDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: taskDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.taskFRC.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    NSString *filterProject = self.activeTask.taskProject.projectName;
    NSString *filterTask = self.activeTask.title;
    NSPredicate *completedPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@ AND completed == 0 AND title !=%@",
                                       filterProject,
                                       filterTask];
    [self.fetchRequest setPredicate:completedPredicate];
    
    self.taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:self.managedObjectContext
                                                         sectionNameKeyPath:nil
                                                                  cacheName:@"taskListCache"];
    
    NSError *requestError = nil;
    if ([self.taskFRC performFetch:&requestError]) {
        self.displayList = [[NSMutableArray alloc] initWithArray:[self.taskFRC fetchedObjects]];
        self.displayList = [self removeIneligibleRecordsFrom:self.displayList];
        [self.tableView reloadData];
    }
    
    if (self.parentTask != nil) {
        NSIndexPath *rowPointer = nil;
        for (Task *task in self.displayList) {
            if (task == self.parentTask) {
                rowPointer = [NSIndexPath indexPathForRow:[self.displayList indexOfObject:task] inSection:0];
                break;
            }
        }
        [self.tableView selectRowAtIndexPath:rowPointer animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.popDelegate = nil;
    self.managedObjectContext = nil;
    self.taskFRC = nil;
    self.fetchRequest = nil;
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
    return [self.displayList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Task *task = [self.displayList objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"projectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.textLabel.text = task.title;
    cell.detailTextLabel.text = task.assignedTo;
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Task *task = [self.displayList objectAtIndex:indexPath.row];
    self.activeTask.superTask = task;
    self.activeTask.visible = [NSNumber numberWithBool:[task isExpanded]];
    int nextLevel = [task.level integerValue];
    nextLevel++;
    self.activeTask.level = [NSNumber numberWithInt:nextLevel];
    float newDisplayOrder = [task.displayOrder floatValue] + 0.1f;
    self.activeTask.displayOrder = [NSNumber numberWithFloat:newDisplayOrder];
    [task addSubTasksObject:self.activeTask];
    [self.popDelegate saveParent];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Lazy Getters
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
