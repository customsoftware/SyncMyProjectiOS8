//
//  CCHotListViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/21/12.
//
//

#import "CCHotListViewController.h"
#import "CCDetailViewController.h"
#define kStartNotification @"ProjectTimerStartNotification"
#define kStartTaskNotification @"TaskTimerStartNotification"
#define kStopNotification @"ProjectTimerStopNotification"

#define TASK_COMPLETE [[NSNumber alloc] initWithInt:1]
#define TASK_ACTIVE [[NSNumber alloc] initWithInt:0]
#define ONE_DAY 24*60*60
#define ONE_WEEK 24*60*60*7
#define ONE_MONTH 24*60*60*7*30

typedef enum khotlistfilterModes{
    allProjectsMode,
    todayMode,
    thisWeekMode,
    categoryMode,
    lateMode
} kHotListFilterModes;

@interface CCHotListViewController ()
@property (strong, nonatomic) NSPredicate *allPredicate;
@property (strong, nonatomic) NSPredicate *todayPredicate;
@property (strong, nonatomic) NSPredicate *nextWeekPredicate;
@property (strong, nonatomic) NSPredicate *nextMonthPredicate;
@property (strong, nonatomic) NSPredicate *latePredicate;
@property (strong, nonatomic) NSDate *startRange;
@property (strong, nonatomic) NSDate *endRange;
@property (strong, nonatomic) NSMutableArray *filteredTasks;
@property (strong, nonatomic) CCEmailer *emailer;
@property (strong, nonatomic) CCHotListReportViewController *hotListReporter;
@property NSInteger selectedFilter;
@property NSInteger selectedSegment;

@end

@implementation CCHotListViewController
@synthesize task = _task;
@synthesize dateFormatter = _dateFormatter;
@synthesize fetchRequest = _fetchRequest;
@synthesize taskFRC = _taskFRC;
@synthesize emailer = _emailer;
@synthesize hotListReporter = _hotListReporter;
@synthesize projectDetailController = _projectDetailController;
@synthesize selectedIndex = _selectedIndex;
@synthesize projectTimer = _projectTimer;
@synthesize filteredTasks = _filteredTasks;

-(void)sendTimerStartNotificationForProject{
    NSDictionary *projectDictionary = @{ @"Project" : self.task.taskProject };
    [[NSNotificationCenter defaultCenter] postNotificationName:kStartNotification object:nil userInfo:projectDictionary];
}

-(void)sendTimerStopNotification{
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
}

-(void)sendTimerStartNotificationForTask{
    NSDictionary *projectDictionary = @{ @"Project" : self.task.taskProject,
                                         @"Task" : self.task };
    NSNotification *startTimer = [NSNotification notificationWithName:kStartTaskNotification object:nil userInfo:projectDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:startTimer];
}


#pragma mark - Delegate actions
-(void)didFinishWithError:(NSError *)error{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)didFinishWithResult:(MFMailComposeResult)result{
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)cancelPopover{
}

-(IBAction)savePopoverData{
}

-(IBAction)filterOptions:(UISegmentedControl *)sender{
    self.selectedFilter = sender.selectedSegmentIndex;
    if (sender.selectedSegmentIndex == allProjectsMode) {
        [self.fetchRequest setPredicate:self.allPredicate];
    } else if ( sender.selectedSegmentIndex == todayMode ) {
        [self.fetchRequest setPredicate:self.todayPredicate];
    } else if ( sender.selectedSegmentIndex == thisWeekMode ) {
        [self.fetchRequest setPredicate:self.nextWeekPredicate];
    } else if ( sender.selectedSegmentIndex == lateMode ) {
        [self.fetchRequest setPredicate:self.latePredicate];
    }
    self.selectedSegment = sender.selectedSegmentIndex;
    [self.projectTimer releaseTimer];
    self.projectTimer = nil;
    
    NSError *fetchError = [[NSError alloc] init];
    [self.taskFRC performFetch:&fetchError];
    [self.tableView reloadData];
}

-(IBAction)sendHotList:(UIBarButtonItem *)sender{
    self.emailer = [[CCEmailer alloc] init];
    self.emailer.emailDelegate = self;
    self.hotListReporter = [[CCHotListReportViewController alloc] init];
    self.emailer.subjectLine = [[NSString alloc] initWithFormat:@"Hot List Report As of %@", [self.dateFormatter stringFromDate:[NSDate date]]];
    self.emailer.messageText = [self.hotListReporter getHotListReportForStatus:self.selectedFilter];
    self.emailer.useHTML = [NSNumber numberWithBool:NO];
    [self.emailer sendEmail];
    [self presentModalViewController:self.emailer.mailComposer animated:YES];
}

-(BOOL)shouldShowCancelButton{
    return  NO;
}

#pragma mark - View Life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *dueWhenDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:YES];
    NSSortDescriptor *projectDescriptor = [[NSSortDescriptor alloc] initWithKey:@"taskProject.dateFinish" ascending:NO];
    NSSortDescriptor *taskDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: dueWhenDescriptor, projectDescriptor, taskDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    [self.fetchRequest setPredicate:self.allPredicate];

    self.taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    
    self.taskFRC.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    NSError *requestError = nil;
    if ([self.taskFRC performFetch:&requestError]) {
        [self.tableView reloadData];
    }
    if (self.selectedIndex != nil) {
        [self.tableView selectRowAtIndexPath:self.selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
 //       [self updateDetailControllerForIndexPath:self.selectedIndex];
    } else if (self.projectTimer != nil){
        [self.projectTimer releaseTimer];
        self.projectTimer = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Search Bar Functionality
-(void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope{
    [self.filteredTasks removeAllObjects];
    NSPredicate *nameLikePredicate = nil;
    if (self.selectedSegment == 3) {
        nameLikePredicate = [NSPredicate predicateWithFormat:@"taskPriority.priority beginswith[c] %@", searchText];
    } else {
        nameLikePredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName beginswith[c] %@", searchText];
    }
    NSArray *workingList = self.taskFRC.fetchedObjects;
    self.filteredTasks = [[NSMutableArray alloc] initWithArray:[workingList filteredArrayUsingPredicate:nameLikePredicate]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}


#pragma mark - Table view data source
-(void)configureCell:(UITableViewCell *)cell{
    
    NSString *detailMessage;
    NSString *ownerName;
    if (self.task.assignedTo == nil) {
        ownerName = @"Self";
    } else {
        ownerName = [[NSString alloc] initWithFormat:@"%@ %@", self.task.assignedFirst, self.task.assignedLast];
    }
    detailMessage = [[NSString alloc] initWithFormat:@"Owner: %@ Due: %@", ownerName, [self.dateFormatter stringFromDate:self.task.dueDate]];
    cell.textLabel.text = [[NSString alloc]initWithFormat:@"%@: %@", self.task.taskProject.projectName, self.task.title];
    cell.detailTextLabel.text = detailMessage;
    if (self.task.notes.length > 0) {
        cell.imageView.image = [UIImage imageNamed:@"179-notepad.png"];
    } else {
        cell.imageView.image = nil;
    }
    
    if (self.selectedSegment == categoryMode) {
        UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(230, 5, 44, 34)];
        catColor.backgroundColor = [self.task.taskPriority getCategoryColor];
        catColor.layer.cornerRadius = 3;
        catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        catColor.layer.borderWidth = 1;
        cell.accessoryView = catColor;
    } else {
        cell.accessoryView = nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger retvalue;
    if (tableView == self.tableView) {
        retvalue = [[self.taskFRC sections] count];
    } else {
        retvalue = 1;
    }
    return retvalue;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger retValue;
    if (tableView == self.tableView) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.taskFRC sections] objectAtIndex:section];
        retValue = [sectionInfo numberOfObjects];
    } else {
        retValue = [self.filteredTasks count];
    }
    return retValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *lateCellIdentifier = @"lateHotCell";
    static NSString *CellIdentifier = @"hotCell";
    UITableViewCell *returnCell = nil;
    
    if (tableView == self.tableView) {
        self.task = [self.taskFRC objectAtIndexPath:indexPath];
    } else {
        self.task = [self.filteredTasks objectAtIndex:indexPath.row];
    }
    
    if ([self.task.isOverDue boolValue] && self.task.completed == TASK_ACTIVE) {
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

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    } */
}

#pragma mark - Table view delegate
-(void)updateDetailControllerForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView{
    [self.projectDetailController.projectNotes resignFirstResponder];
    // self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    
    /*if (tableView == self.tableView) {
        self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        self.activeProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }*/
    
    self.projectDetailController.project = self.task.taskProject;
    self.projectDetailController.controllingCellIndex = indexPath;
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForProject];
    
    self.projectDetailController.activeTimer = self.projectTimer;
    
    if (self.task.taskProject.projectNotes) {
        self.projectDetailController.projectNotes.text = self.task.taskProject.projectNotes;
    } else {
        self.projectDetailController.projectNotes.text = [[NSString alloc] initWithFormat:@"Enter notes about the %@ project here", self.task.taskProject.projectName];
    }
    self.projectDetailController.title = [[NSString alloc] initWithFormat:@"%@: Notes", self.task.taskProject.projectName ];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.projectDetailController.project.projectNotes = self.projectDetailController.projectNotes.text;
    [self.projectTimer releaseTimer];
    self.projectTimer = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (tableView == self.tableView) {
        self.task = [self.taskFRC objectAtIndexPath:indexPath];
    } else {
        self.task = [self.filteredTasks objectAtIndex:indexPath.row];
    }
    
    if (self.selectedIndex.row == indexPath.row && self.projectTimer != nil ) {
        // Do nothing
    } else {
        [self sendTimerStartNotificationForTask];
        self.selectedIndex = indexPath;
        if (tableView == self.tableView){
            [self updateDetailControllerForIndexPath:indexPath inTable:tableView];
        } else {
            [self updateDetailControllerForIndexPath:indexPath inTable:self.searchDisplayController.searchResultsTableView];
        }
    }
    CCTaskViewDetailsController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskDetails"];
    detailViewController.activeTask = self.task;
    detailViewController.selectedIndexPath = indexPath;
    detailViewController.taskDelegate = self;
    NSString *enableNotification = [[NSString alloc] initWithFormat:@"%@", @"EnableControlsNotification"];
    NSNotification *enableControls = [NSNotification notificationWithName:enableNotification object:nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] postNotification:enableControls];
    }
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - Date methods
-(NSDate *)today{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc] init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:components.day];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)nextWeek{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [self today];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:components.day+7];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)nextMonth{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc]init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setMonth:components.month+1];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

#pragma mark - Lazy getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

-(NSPredicate *)allPredicate {
    if (_allPredicate == nil) {
        _allPredicate = [NSPredicate predicateWithFormat:@"completed == 0 AND dueDate != nil"];
    }
    return _allPredicate;
}

-(NSPredicate *)todayPredicate {
    if (_todayPredicate == nil) {
        self.startRange = [self today];
        self.endRange = [[NSDate alloc] initWithTimeInterval:ONE_DAY sinceDate:self.startRange];
        _todayPredicate = [NSPredicate predicateWithFormat:@"completed == 0 AND dueDate >=%@ AND dueDate <= %@", self.startRange, self.endRange];
    }
    return _todayPredicate;
}

-(NSPredicate *)nextWeekPredicate {
    if (_nextWeekPredicate == nil) {
        self.startRange = [self today];
        self.endRange = [[NSDate alloc] initWithTimeInterval:ONE_WEEK sinceDate:self.startRange];
        
        _nextWeekPredicate = [NSPredicate predicateWithFormat:@"completed == 0 AND dueDate >=%@ AND dueDate <= %@", self.startRange, self.endRange];
    }
    return _nextWeekPredicate;
}

-(NSPredicate *)nextMonthPredicate {
    if (_nextMonthPredicate == nil) {
        self.startRange = [self today];
        self.endRange = [[NSDate alloc] initWithTimeInterval:ONE_MONTH sinceDate:self.startRange];
        
        _nextMonthPredicate = [NSPredicate predicateWithFormat:@"completed == 0 AND dueDate >=%@ AND dueDate <= %@", self.startRange, self.endRange];
    }
    return _nextMonthPredicate;
}

-(NSPredicate *)latePredicate {
    if (_latePredicate == nil) {
        self.startRange = [self today];
        _latePredicate = [NSPredicate predicateWithFormat:@"completed == 0 AND dueDate <= %@", self.startRange];
    }
    return _latePredicate;
}

@end
