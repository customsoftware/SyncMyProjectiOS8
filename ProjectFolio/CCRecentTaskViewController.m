//
//  CCRecentTaskViewController.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/14/13.
//
//

#import "CCRecentTaskViewController.h"
#import "CCMostRecentTasks.h"
#import "CCExpenseNotesViewController.h"
#import "CCTaskViewDetailsController.h"
#import "CCiPhoneDetailViewController.h"

#define kStartNotification      @"ProjectTimerStartNotification"
#define kStartTaskNotification  @"TaskTimerStartNotification"
#define kStopNotification       @"ProjectTimerStopNotification"
#define kChoiceStorageKey       @"recentRecordChoice"

typedef enum kChoiceModes{
    fiveRecents = 0,
    fifteenRecents,
    thirtyRecents
} kChoiceModes;

@interface CCRecentTaskViewController () <CCNotesDelegate, CCPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterOptions;
@property (strong, nonatomic) NSArray *recentTasks;
@property (strong, nonatomic) Task *currentTask;
@property (strong, nonatomic) CCExpenseNotesViewController *notesController;
@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSSortDescriptor *sorter;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSFetchedResultsController *taskFRC;
@property (strong, nonatomic) NSEntityDescription *entity;
@property (strong, nonatomic) CCiPhoneDetailViewController *detailController;

- (IBAction)showNotes:(UIBarButtonItem *)sender;
- (IBAction)selectFilterOption:(UISegmentedControl *)sender;
@end

@implementation CCRecentTaskViewController

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
    // Add swipe to show notes
    UISwipeGestureRecognizer *showExtrasSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    showExtrasSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:showExtrasSwipe];
    [self updateDetailControllerForIndexPath:nil inTable:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    int option = [[NSUserDefaults standardUserDefaults] integerForKey:kChoiceStorageKey];
    [self runQuery:option];
    if (self.currentTask) {
        NSDictionary *dictionary = @{@"workProject.projectName":self.currentTask.taskProject.projectName,
                                     @"workTask.title":self.currentTask.title};
        
        int rowNum = [self.recentTasks indexOfObject:dictionary];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:rowNum inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    self.filterOptions.selectedSegmentIndex = option;
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

#pragma mark - <CCPopover >
-(IBAction)savePopoverData{
    
}

-(IBAction)cancelPopover {
    
}

-(BOOL)shouldShowCancelButton {
    return NO;
}

#pragma mark - <UITableViewDataSource>
- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    static NSString *cellID = @"recentCell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    NSDictionary *dictionary = self.recentTasks[indexPath.row];
    
    cell.textLabel.text = dictionary[@"workTask.title"];
    cell.detailTextLabel.text = dictionary[@"workProject.projectName"];
    return cell;
}

#pragma mark - <UITableViewDelegate>
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.currentTask = [self getTaskAtIndexPath:indexPath];
    CCTaskViewDetailsController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskDetails"];
    detailViewController.activeTask = self.currentTask;
    detailViewController.selectedIndexPath = indexPath;
    detailViewController.taskDelegate = self;
    [self updateDetailControllerForIndexPath:indexPath inTable:tableView];
    NSString *enableNotification = [[NSString alloc] initWithFormat:@"%@", @"EnableControlsNotification"];
    NSNotification *enableControls = [NSNotification notificationWithName:enableNotification object:nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] postNotification:enableControls];
    }
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - Outlets and Actions
- (IBAction)showNotes:(UIBarButtonItem *)sender {
    self.detailController.project = self.currentTask.taskProject;
    [self.navigationController pushViewController:self.detailController animated:YES];
}

- (IBAction)selectFilterOption:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:kChoiceStorageKey];
    [self runQuery:sender.selectedSegmentIndex];
}

#pragma mark - Helper
-(void)sendTimerStopNotification{
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
}

-(void)sendTimerStartNotificationForTask{
    if (self.currentTask) {
        NSDictionary *projectDictionary = @{ @"Project" : self.currentTask.taskProject,
                                             @"Task" : self.currentTask };
        NSNotification *startTimer = [NSNotification notificationWithName:kStartTaskNotification object:nil userInfo:projectDictionary];
        [[NSNotificationCenter defaultCenter] postNotification:startTimer];
    }
}

-(void)updateDetailControllerForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView{
    [self.projectDetailController.projectNotes resignFirstResponder];
    self.projectDetailController.project = self.currentTask.taskProject;
    self.projectDetailController.controllingCellIndex = indexPath;
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForTask];
    
    self.projectDetailController.activeTimer = self.projectTimer;
    
    if (self.currentTask) {
        if (self.currentTask.taskProject.projectNotes) {
            self.projectDetailController.projectNotes.text = self.currentTask.taskProject.projectNotes;
        } else {
            self.projectDetailController.projectNotes.text = [[NSString alloc] initWithFormat:@"Enter notes for %@ project here", self.currentTask.taskProject.projectName];
        }
        self.projectDetailController.title = [[NSString alloc] initWithFormat:@"%@: Notes", self.currentTask.taskProject.projectName ];
    } else {
        self.projectDetailController.title = @"Notes";
        self.projectDetailController.projectNotes.text = @"";
    }
}

- (void)runQuery:(int)choiceOption {
    switch (choiceOption) {
        case fiveRecents:
            self.recentTasks = [CCMostRecentTasks mostRecentTasks:5];
            break;
            
        case fifteenRecents:
            self.recentTasks = [CCMostRecentTasks mostRecentTasks:15];
            break;
            
        case thirtyRecents:
            self.recentTasks = [CCMostRecentTasks mostRecentTasks:30];
            break;
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
    self.currentTask = [self getTaskAtIndexPath:swipedIndexPath];
    if (self.currentTask) {
        [self.tableView selectRowAtIndexPath:swipedIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        // Show notes here
        self.notesController = [self.storyboard instantiateViewControllerWithIdentifier:@"expenseNotes"];
        self.notesController.modalPresentationStyle = UIModalPresentationFormSheet;
        self.notesController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        self.notesController.notesDelegate = self;
        [self presentViewController:self.notesController animated:YES completion:nil];
    }
}

- (Task *)getTaskAtIndexPath:(NSIndexPath *)indexPath {
    // Run a query that pulls back the task
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    Task *retTask = nil;
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"(title == %@) AND ( taskProject.projectName == %@)", cell.textLabel.text, cell.detailTextLabel.text];
    
    [self.request setSortDescriptors:@[self.sorter]];
    [self.request setEntity:self.entity];
    [self.request setPredicate:filter];
    
    NSError *error = nil;
    [self.taskFRC performFetch:&error];
    
    if (self.taskFRC.fetchedObjects.count > 0) {
        retTask = self.taskFRC.fetchedObjects.firstObject;
    }
    return retTask;
}

#pragma mark - Accessors
- (NSFetchedResultsController *)taskFRC {
    if (!_taskFRC) {
        _taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request
                                                       managedObjectContext:self.context
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    }
    
    return _taskFRC;
}

- (NSEntityDescription *)entity{
    if (!_entity) {
        _entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.context];
    }
    
    return _entity;
}

- (NSFetchRequest *)request{
    if (!_request ) {
        _request = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    }
    return _request;
}

- (NSSortDescriptor *)sorter {
    if (!_sorter){
        _sorter = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO];
    }
    return _sorter;
}

- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [[CoreData sharedModel:nil] managedObjectContext];
    }
    
    return _context;
}

-(CCiPhoneDetailViewController *)detailController{
    if (_detailController == nil) {
        _detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"detailViewController"];
    }
    return _detailController;
}

@end
