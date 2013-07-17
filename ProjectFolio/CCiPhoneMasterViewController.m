//
//  CCiPhoneMasterViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/26/12.
//
//
#define START_INDEX [NSIndexPath indexPathForRow:0 inSection:0]
#define END_INDEX [NSIndexPath indexPathForRow:1 inSection:0]
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]
#define kFontNameKey @"font"
#define kFontSize @"fontSize"
#define kBlueNameKey @"bluebalance"
#define kRedNameKey @"redbalance"
#define kGreenNameKey @"greenbalance"
#define kSaturation @"saturation"
#define kStartNotification @"ProjectTimerStartNotification"
#define kStopNotification @"ProjectTimerStopNotification"
#define kSelectedProject @"activeProject"

#import "CCiPhoneMasterViewController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCHotListViewController.h"

typedef enum kfilterModes{
    allProjectsMode,
    activeProjectsMode,
    openProjectsMode,
    categoryMode,
    hotListMode
} kFilterModes;

@interface CCiPhoneMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView;
@property (strong, nonatomic) CCGeneralCloser *closer;
@property (strong, nonatomic) CCiPhoneTaskViewController *mainTaskController;
@property (strong, nonatomic) Project *activeProject;
@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSPredicate *activePredicate;
@property (strong, nonatomic) NSPredicate *openPredicate;
@property (strong, nonatomic) CCHotListViewController *hotListController;
@property NSInteger lastSelected;
@property (strong, nonatomic) NSMutableArray *filteredProjects;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@end

@implementation CCiPhoneMasterViewController

-(void)sendTimerStartNotificationForProject{
    NSDictionary *projectDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:self.activeProject, @"Project", nil];
    NSNotification *startTimer = [NSNotification notificationWithName:kStartNotification object:nil userInfo:projectDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:startTimer];
}

-(void)sendTimerStopNotification{
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
}


#pragma mark - IBActions
-(IBAction)filterActions:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == hotListMode){
        // self.hotListController.projectDetailController = self.detailViewController;
        [self.navigationController pushViewController:self.hotListController animated:YES];
        sender.selectedSegmentIndex = self.lastSelected;
        [self sendTimerStopNotification];
    } else {
        self.lastSelected = sender.selectedSegmentIndex;
        if (sender.selectedSegmentIndex == allProjectsMode) {
            [self.request setPredicate:nil];
        } else if ( sender.selectedSegmentIndex == activeProjectsMode ) {
            [self.request setPredicate:self.activePredicate];
        } else if ( sender.selectedSegmentIndex == openProjectsMode ) {
            [self.request setPredicate:self.openPredicate];
        }
        NSError *fetchError = [[NSError alloc] init];
        [self.fetchedProjectsController performFetch:&fetchError];
        [self.tableView reloadData];
        
        for (Project *project in self.fetchedProjectsController.fetchedObjects ) {
            if (self.activeProject == project) {
                NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }
        
    }
}

-(IBAction)actionButton:(UIBarButtonItem *)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Close Projects" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"This Week", @"Yesterday", @"All Active", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - Popover Controls
-(void)showProjectDatePicker:(NSIndexPath *)sender{
    // Configure the popover view
    self.projectPopover = [self.storyboard instantiateViewControllerWithIdentifier:@"projectPopper"];
    self.controllingCellIndex = sender;
    self.controllingCell = [self.tableView cellForRowAtIndexPath:sender];
    Project *project = [self.fetchedProjectsController objectAtIndexPath:sender];
    self.projectPopover.project = project;
    self.projectPopover.contentSizeForViewInPopover = CGSizeMake(320.0f, 560.0f);
    [self.navigationController pushViewController:self.projectPopover animated:YES];
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

#pragma mark - Search Bar Functionality
-(void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope{
    [self.filteredProjects removeAllObjects];
    NSPredicate *nameLikePredicate = nil;
    if (self.lastSelected == 3) {
        nameLikePredicate = [NSPredicate predicateWithFormat:@"projectPriority.priority beginswith[c] %@", searchText];
    } else {
        nameLikePredicate = [NSPredicate predicateWithFormat:@"projectName beginswith[c] %@", searchText];
    }
    NSArray *workingList = self.fetchedProjectsController.fetchedObjects;
    self.filteredProjects = [[NSMutableArray alloc] initWithArray:[workingList filteredArrayUsingPredicate:nameLikePredicate]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar
                                                          scopeButtonTitles]
                                                         objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

#pragma mark - ActionSheet Functionality
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result == MFMailComposeResultCancelled) {
        // NSLog(@"Leave the timers intact");
    } else {
        [self.closer billEvents];
    }
    [self dismissModalViewControllerAnimated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    self.closer = nil;
    switch (buttonIndex) {
        case 2:
            self.closer = [[CCGeneralCloser alloc] initForAll];
            [self.closer setMessage];
            [self.navigationController presentModalViewController:self.closer.mailComposer animated:YES];
            break;
            
        case 0:
            self.closer = [[CCGeneralCloser alloc] initWithLastWeek];
            [self.closer setMessage];
            [self.navigationController presentModalViewController:self.closer.mailComposer animated:YES];
            break;
            
        case 1:
            self.closer = [[CCGeneralCloser alloc] initForYesterday];
            [self.closer setMessage];
            [self.navigationController presentModalViewController:self.closer.mailComposer animated:YES];
            break;
            
        default:
            // NSLog(@"Cancelling this");
            break;
    }
}

#pragma mark - Alert Functionality
-(NSString *)yesButtonTitle{
    return @"OK";
}

-(NSString *)noButtonTitle{
    return @"Not now";
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if([buttonTitle isEqualToString:[self yesButtonTitle]]){
        if ([[alertView textFieldAtIndex:0].text isEqualToString:@""]) {
        } else {
            Project *newProject = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"Project"
                                   inManagedObjectContext:self.managedObjectContext];
            if (newProject == nil) {
                self.logger = [[CCErrorLogger alloc] initWithErrorString:@"Failed to create a new project" andDelegate:self];
                [self.logger releaseLogger];
            } else {
                newProject.projectName = [alertView textFieldAtIndex:0].text;
                newProject.dateCreated = [NSDate date];
                newProject.dateStart = newProject.dateCreated;
                newProject.projectNotes = [[NSString alloc] initWithFormat:@"Enter notes for %@ project here", newProject.projectName];
                
                NSError *error = [[NSError alloc] init];
                @try {
                    if (![self.managedObjectContext save:&error]){
                        self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                        [self.logger releaseLogger];
                    }
                    self.activeProject = newProject;
                    NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
                    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                }
                @catch (NSException *exception) {
                    self.logger = [[CCErrorLogger alloc] initWithErrorString:exception.reason andDelegate:self];
                    [self.logger releaseLogger];
                }
            }
        }
    }
}

-(void)releaseLogger{
    self.logger = nil;
}

#pragma mark - View lifecycle

- (void)awakeFromNib
{
    // self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // self.detailViewController = (CCDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    // Set up the add button.
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Set up the search controller
    self.searchDisplayController.delegate = self;
    self.projectTimer = [[CCProjectTimer alloc] init];
}

-(void)viewWillAppear:(BOOL)animated{
    NSString *enableNotification = @"EnableControlsNotification";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableControls) name:enableNotification object:nil];
    if (self.hotListController.projectTimer != nil) {
        [self.hotListController.projectTimer releaseTimer];
        self.hotListController.selectedIndex = nil;
    }
    if (self.activeProject != nil ){
        [self sendTimerStartNotificationForProject];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *tempProject = [defaults objectForKey:kSelectedProject];
        // CCSettingsControl *settings = [[CCSettingsControl alloc] init];
        // NSString *tempProject = [settings recallStringAtKey:kSelectedProject];
        
        if (tempProject == nil) {
            tempProject = [[NSString alloc]initWithFormat:@"Sample Project"];
        }
        for (Project *project in [self.fetchedProjectsController fetchedObjects]) {
            if ([project.projectUUID isEqualToString:tempProject]) {
                NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:project];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
    }
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIAlertView *alert = nil;
    if (![application iCloudIsAvailableNow]) {
        alert = [[UIAlertView alloc] initWithTitle:@"iCloud Availability" message:@"The cloud is not available now" delegate:self cancelButtonTitle:@"Bummer" otherButtonTitles:nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"iCloud Availability" message:@"The cloud is available now" delegate:self cancelButtonTitle:@"Kewel" otherButtonTitles:nil];
    }
    // [alert show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Public functionality
-(Project *)getActiveProject{
    return self.activeProject;
}

#pragma mark - Table Controls
-(void)updateDetailControllerForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView{
    if (tableView == self.tableView) {
        self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        self.activeProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForProject];
    self.controllingCellIndex = indexPath;
    self.controllingCell = [self.tableView cellForRowAtIndexPath:indexPath];
}


-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    // Need to invoke popover from here
    [self resignFirstResponder];
    [self showProjectDatePicker:indexPath];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger retvalue;
    if (tableView == self.tableView) {
        retvalue = [[self.fetchedProjectsController sections] count];
    } else {
        retvalue = 1;
    }
    return retvalue;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger retValue;
    if (tableView == self.tableView) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedProjectsController sections] objectAtIndex:section];
        retValue = [sectionInfo numberOfObjects];
    } else {
        retValue = [self.filteredProjects count];
    }
    return retValue;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    static NSString *CellIdentifier = @"Cell";
    static NSString *lateCellIdentifier = @"lateCell";
    Project *project = nil;
    
    if (tableView == self.tableView) {
        project = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        project = [self.filteredProjects objectAtIndex:indexPath.row];
        // NSLog(@"Project name: %@", project.projectName);
    }
    
    
    
    if ([project.isOverDue boolValue] == YES) {
        cell = [tableView dequeueReusableCellWithIdentifier:lateCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                          reuseIdentifier:lateCellIdentifier];
        }
    } else{
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:CellIdentifier];
        }
    }
    
    [self configureCell:cell atIndexPath:indexPath inTable:tableView];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    BOOL retValue = YES;
    if (tableView == self.tableView) {
        retValue = YES;
    } else {
        retValue = NO;
    }
    return retValue;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the managed object for the given index path
            [self sendTimerStopNotification];
            self.activeProject = nil;
            self.controllingCellIndex = nil;
            [self.managedObjectContext deleteObject:[self.fetchedProjectsController objectAtIndexPath:indexPath]];
            
            // Save the context.
            NSError *error = [[NSError alloc] init];
            @try {
                if (![self.managedObjectContext save:&error]){
                    self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                    [self.logger releaseLogger];
                }
            }
            @catch (NSException *exception) {
                self.logger = [[CCErrorLogger alloc] initWithErrorString:exception.reason andDelegate:self];
                [self.logger releaseLogger];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        [self sendTimerStopNotification];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if ([self.controllingCellIndex row] != [indexPath row] || self.controllingCellIndex == nil ) {
        [self updateDetailControllerForIndexPath:indexPath inTable:tableView];
        }
    } else {
        [self updateDetailControllerForIndexPath:indexPath inTable:self.searchDisplayController.searchResultsTableView];
    }
    
    self.mainTaskController.projectDelegate = self;
    [self.navigationController pushViewController:self.mainTaskController animated:YES];
}

#pragma mark - Fetched results controller
-(void)persistentStoreDidChange{
    NSError *error = nil;
    [self.fetchedProjectsController performFetch:&error];
    [self.tableView reloadData];
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

-(NSFetchedResultsController *)fetchedProjectsController{
    NSFetchedResultsController *retvalue;
    if (_fetchedProjectsController != nil) {
        retvalue = _fetchedProjectsController;
    } else {
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                  inManagedObjectContext:self.managedObjectContext];
        [self.request setEntity:entity];
        [self.request setFetchBatchSize:20];
        
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"active" ascending:NO];
        NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
        NSSortDescriptor *endDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateFinish" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, completeDescriptor, endDateDescriptor, nil];
        [self.request setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        aFetchedResultsController.delegate = self;
        
        self.fetchedProjectsController = aFetchedResultsController;
        
        NSError *error = nil;
        @try {
            if(![self.fetchedProjectsController performFetch:&error]){
                self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.logger releaseLogger];
            }
        }
        @catch (NSException *exception) {
            self.logger = [[CCErrorLogger alloc] initWithErrorString:exception.reason andDelegate:self];
            [self.logger releaseLogger];
        }
        
        retvalue = _fetchedProjectsController;
    }
    return retvalue;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath inTable:tableView];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}



/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView
{
    Project *newProject = nil;
    if (self.tableView == tableView) {
        newProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        newProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = [[NSString alloc] initWithFormat:@"%@", newProject.projectName];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    
    BOOL completeVal = (newProject.complete == SWITCH_ON) ? YES:NO;
    BOOL activeVal = (newProject.active == SWITCH_ON) ? YES:NO;
    
    NSString *endDate;
    if (newProject.dateFinish == nil) {
        endDate = @"Not set";
    } else {
        endDate = [formatter stringFromDate:newProject.dateFinish];
    }
    NSString *startDate;
    if (newProject.dateStart == nil) {
        startDate = @"Not set";
    } else {
        startDate = [formatter stringFromDate:newProject.dateStart];
    }
    
    NSString *caption;
    if (completeVal == NO & activeVal == YES) {
        caption = [[NSString alloc] initWithFormat:@"Target date: %@", endDate];
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == NO){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"checkmark-box-small-green.png"];
    } else if ( completeVal == NO & activeVal == NO){
        caption = [[NSString alloc] initWithFormat:@"Should start: %@", startDate];
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == YES){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"checkmark-box-small-green.png"];
    } else {
        caption = [[NSString alloc] initWithFormat:@"Should finish: %@", endDate];
        cell.imageView.image = nil;
    }
    
    if (self.lastSelected == categoryMode) {
        UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(230, 5, 44, 34)];
        catColor.backgroundColor = [newProject.projectPriority getCategoryColor];
        catColor.layer.cornerRadius = 3;
        catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        catColor.layer.borderWidth = 1;
        cell.accessoryView = catColor;
    } else {
        cell.accessoryView = nil;
    }
    
    cell.detailTextLabel.text = caption;
}

- (void)insertNewObject
{
    UIAlertView *alertViewProjectName = [[UIAlertView alloc]
                                         initWithTitle:@"Project Name"
                                         message:@"Please enter a name for the project"
                                         delegate:self
                                         cancelButtonTitle:[self noButtonTitle]
                                         otherButtonTitles:[self yesButtonTitle],nil];
    alertViewProjectName.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alertViewProjectName show];
}

#pragma mark - Lazy getters
-(NSManagedObjectContext *)managedObjectContext{
    if (_managedObjectContext == nil) {
        CoreData *sharedModel = [CoreData sharedModel:self];
        _managedObjectContext = sharedModel.managedObjectContext;
        
    }
    return _managedObjectContext;
}

-(CCiPhoneTaskViewController *)mainTaskController{
    if (_mainTaskController == nil) {
        _mainTaskController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainTaskList"];
        
    }
    return _mainTaskController;
}

-(NSFetchRequest *)request{
    if (_request == nil) {
        _request = [[NSFetchRequest alloc] init];
    }
    return _request;
}

-(NSPredicate *)activePredicate {
    if (_activePredicate == nil) {
        _activePredicate = [NSPredicate predicateWithFormat:@"active == 1"];
    }
    return _activePredicate;
}

-(NSPredicate *)openPredicate{
    if (_openPredicate == nil) {
        _openPredicate = [NSPredicate predicateWithFormat:@"complete == 0"];
    }
    return _openPredicate;
}

-(CCHotListViewController *)hotListController{
    if (_hotListController == nil) {
        _hotListController = [self.storyboard instantiateViewControllerWithIdentifier:@"hotListView"];
    }
    return _hotListController;
}

@end
