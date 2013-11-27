//
//  CCiPhoneMasterViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 11/26/12.
//
//
#define START_INDEX [NSIndexPath indexPathForRow:0 inSection:0]
#define END_INDEX [NSIndexPath indexPathForRow:1 inSection:0]
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]

#define kStartNotification  @"ProjectTimerStartNotification"
#define kStopNotification   @"ProjectTimerStopNotification"
#define kSearchState        @"searchMode"
#define kActiveProject      @"activeProject"
#define kRowHeight          47
#define kRecentsIndexKey    3

#import "CCiPhoneMasterViewController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCHotListViewController.h"
#import "CCiPhoneDetailViewController.h"
#import "CCLatestNewsViewController.h"
#import "iCloudStarterProtocol.h"
#import "CCAppDelegate.h"
#import "CCPrintNotesRender.h"
#import "CCRecentTaskViewController.h"
#import "ProjectCell.h"

typedef enum kfilterModes{
    allProjectsMode,
    activeProjectsMode,
    projectCategoryMode,
    recentListMode,
    hotListMode
} kFilterModes;

@interface CCiPhoneMasterViewController () <CCPopoverControllerDelegate, iCloudStarterProtocol>

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView;

@property (strong, nonatomic) CCGeneralCloser *closer;
@property (strong, nonatomic) CCiPhoneTaskViewController *mainTaskController;
@property (strong, nonatomic) Project *activeProject;
@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSPredicate *activePredicate;
@property (strong, nonatomic) NSPredicate *openPredicate;
@property (strong, nonatomic) CCHotListViewController *hotListController;
@property (strong, nonatomic) CCRecentTaskViewController *recentListController;
@property NSInteger lastSelected;
@property (strong, nonatomic) NSMutableArray *filteredProjects;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@property (nonatomic) BOOL notInSearchMode;
@property (strong, nonatomic) CCiPhoneDetailViewController *detailController;
@property (weak, nonatomic) CCAuxSettingsViewController *settings;
@property (nonatomic) BOOL inICloudMode;
@property (strong, nonatomic) CCSettingsControl *systemSettings;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *projectActionsButton;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterSegmentControl;
@property (strong, nonatomic) NSString *lastProjectID;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

-(IBAction)filterActions:(UISegmentedControl *)sender;
-(IBAction)actionButton:(UIButton *)sender;
-(IBAction)insertNewObject:(UIButton *)sender;
-(IBAction)showSettings:(UIButton *)sender;
-(IBAction)openFAQ:(UIButton *)sender;

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
    } else if (sender.selectedSegmentIndex == recentListMode){
        [self.navigationController pushViewController:self.recentListController animated:YES];
        sender.selectedSegmentIndex = self.lastSelected;
        [self sendTimerStopNotification];
    } else {
        self.lastSelected = sender.selectedSegmentIndex;
        [[NSUserDefaults standardUserDefaults] setInteger:self.lastSelected forKey:kProjectFilterStatus];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (sender.selectedSegmentIndex == allProjectsMode) {
            [self.request setPredicate:nil];
        } else if ( sender.selectedSegmentIndex == activeProjectsMode ) {
            [self.request setPredicate:self.openPredicate];
        }
        
        if (sender.selectedSegmentIndex == projectCategoryMode) {
            self.searchBar.placeholder = @"Enter category name";
        } else {
            self.searchBar.placeholder = @"Enter project name";
        }
        
        NSError *fetchError = [[NSError alloc] init];
        [self.fetchedProjectsController performFetch:&fetchError];
        [self.tableView reloadData];
        
        NSIndexPath *indexPath = nil;
        for (Project *project in self.fetchedProjectsController.fetchedObjects ) {
            if (self.activeProject == project) {
                indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }
        
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }
}

-(IBAction)actionButton:(UIButton *)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Close Projects" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"This Week", @"Yesterday", @"All Active", nil];
    actionSheet.tag = 1;
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
    self.projectPopover.preferredContentSize = CGSizeMake(320.0f, 560.0f);
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
    if (self.lastSelected == projectCategoryMode) {
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self.searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO];
}

#pragma mark - ActionSheet Functionality
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result == MFMailComposeResultCancelled) {
        // NSLog(@"Leave the timers intact");
    } else {
        [self.closer billEvents];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag == 1) {
    self.closer = nil;
    switch (buttonIndex) {
        case 2:
            self.closer = [[CCGeneralCloser alloc] initForAllFor:self];
            [self.closer setMessage];
            break;
            
        case 0:
            self.closer = [[CCGeneralCloser alloc] initWithLastWeekFor:self];
            [self.closer setMessage];
            break;
            
        case 1:
            self.closer = [[CCGeneralCloser alloc] initForYesterdayFor:self];
            [self.closer setMessage];
            break;
            
        default:
            // NSLog(@"Cancelling this");
            break;
    }
    } else if ( actionSheet.tag == 2 ) {
        switch (buttonIndex) {
            case 0:
                [self.closer emailMessage];
                [self.navigationController presentViewController:self.closer.mailComposer animated:YES completion:nil];
                break;
                
            case 1:
                [self printReport];
                break;
                
            default:
                break;
        }
    }
}

- (void)printReport{
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.jobName = self.activeProject.projectName;
    pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *notesFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                  initWithMarkupText:self.closer.messageString];
    notesFormatter.startPage = 0;
    CCPrintNotesRender *renderer = [[CCPrintNotesRender alloc] init];
    renderer.headerString = @"Billable Hour Summary";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    renderer.fontName = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    renderer.fontSize = [defaults integerForKey:kFontSize];
    [renderer addPrintFormatter:notesFormatter startingAtPageAtIndex:0];
    pic.printPageRenderer = renderer;
    pic.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
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
            // Uncheck the current project
            if (self.controllingCell) {
                self.controllingCell = nil;
                self.controllingCellIndex = nil;
            }
            
            Project *newProject = [CoreData createProjectWithName:[alertView textFieldAtIndex:0].text];
//            Project *newProject = [NSEntityDescription
//                                   insertNewObjectForEntityForName:@"Project"
//                                   inManagedObjectContext:self.managedObjectContext];
            if (newProject == nil) {
                self.logger = [[CCErrorLogger alloc] initWithErrorString:@"Failed to create a new project" andDelegate:self];
                [self.logger releaseLogger];
            } else {
                newProject.projectName = [alertView textFieldAtIndex:0].text;
                newProject.dateCreated = [NSDate date];
                newProject.dateStart = newProject.dateCreated;
                newProject.active = [NSNumber numberWithBool:YES];
                newProject.projectUUID = [[CoreData sharedModel:nil] getUUID];
                
                NSError *error = [[NSError alloc] init];
                @try {
                    if (![newProject.managedObjectContext save:&error]){
                        self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                        [self.logger releaseLogger];
                    }
                    self.activeProject = newProject;
                    NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                    self.controllingCellIndex = indexPath;
                    self.controllingCell = cell;
                    [self.tableView reloadData];
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
    if ([self respondsToSelector:@selector(preferredContentSize)]) {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
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
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Set up the search controller
    self.searchDisplayController.delegate = self;
    self.projectTimer = [[CCProjectTimer alloc] init];
    [self.projectTimer restartTimer];
    
    CCLatestNewsViewController *latestController = [self.storyboard instantiateViewControllerWithIdentifier:@"latestNews"];
    latestController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    latestController.popDelegate = self;
    BOOL showNews = [[NSUserDefaults standardUserDefaults] boolForKey:@"dontShowNewsAgain"];
    if (!showNews) {
        [self.navigationController pushViewController:latestController animated:YES];
    }
    
    // Add swipe gesture recognizer to default, unfiltered table view
    UISwipeGestureRecognizer *showExtrasSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    showExtrasSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:showExtrasSwipe];
    
    // Add swipe gesture recognizer to add projects
    self.swiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(insertNewObject:)];
    [self.swiper setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.navigationController.navigationBar addGestureRecognizer:self.swiper];
    
    self.inICloudMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudStarted"];
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [application registeriCloudDelegate:self];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.hotListController.projectTimer != nil) {
        [self.hotListController.projectTimer releaseTimer];
        self.hotListController.selectedIndex = nil;
    }
    
    if (self.recentListController.projectTimer != nil) {
        [self.recentListController.projectTimer releaseTimer];
    }
    
    self.lastSelected = [[NSUserDefaults standardUserDefaults] integerForKey:kProjectFilterStatus];
    self.filterSegmentControl.selectedSegmentIndex = self.lastSelected;
    [self filterActions:self.filterSegmentControl];
    self.swiper.enabled = YES;
    [[CoreData sharedModel:nil] testProjectCount];
    [[CoreData sharedModel:nil] testPriorityConfig];
    [self.filterSegmentControl setEnabled:[self.systemSettings isTimeAuthorized] forSegmentAtIndex:kRecentsIndexKey];
    self.actionButton.enabled = [self.systemSettings isTimeAuthorized];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self setTintForApp];
    
    if (self.activeProject != nil ){
        [self sendTimerStartNotificationForProject];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.lastProjectID = [defaults objectForKey:kSelectedProject];
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.swiper.enabled = NO;
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Setters
- (void)setActiveProject:(Project *)activeProject {
    _activeProject = activeProject;
    self.lastProjectID = activeProject.projectUUID ? activeProject.projectUUID:nil;
}

#pragma mark - Helper
- (void)setTintForApp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float blueTint = [defaults floatForKey:kBlueTintNameKey];
    float redTint = [defaults floatForKey:kRedTintNameKey];
    if ( blueTint != 0 && redTint != 0) {
        CGFloat alpha = [defaults floatForKey:kTintSaturation];
        CGFloat red = [defaults floatForKey:kRedTintNameKey];
        CGFloat blue = [defaults floatForKey:kBlueTintNameKey];
        CGFloat green = [defaults floatForKey:kGreenTintNameKey];
        UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
        [[UIApplication sharedApplication] keyWindow].tintColor = newColor;
    }
}

- (void)sendOutput{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Send Email" otherButtonTitles:@"Print Report", nil];
    sheet.tag = 2;
    [sheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
}

-(IBAction)showSettings:(UIButton *)sender{
    self.settings = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsMain"];
    [self.navigationController pushViewController:self.settings animated:YES];
}

-(IBAction)openFAQ:(UIButton *)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ktcsoftware.com/pf/faq/faq.html"]];
}

- (void)respondToiCloudUpdate {
    [self.fetchedProjectsController performFetch:nil];
    [self.tableView reloadData];
    [[CoreData sharedModel:nil] testProjectCount];
    [[CoreData sharedModel:nil] testPriorityConfig];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kHelpTest];
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"iCloudStarted"];
}

#pragma mark - <CCPopoverControllerDelegate>
- (void)savePopoverData {
    NSLog(@"Implemented just to keep the compiler happy. Not used");
}

- (void)cancelPopover {
    NSLog(@"Implemented just to keep the compiler happy. Not used");
}

-(Project *)getActiveProject{
    return self.activeProject;
}

#pragma mark - Table Controls
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kRowHeight;
}

-(void)updateDetailControllerForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView{
    if (tableView == self.tableView) {
        self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        self.activeProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.activeProject.projectUUID forKey:kActiveProject];
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForProject];
    self.controllingCellIndex = indexPath;
    self.controllingCell = [self.tableView cellForRowAtIndexPath:indexPath];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
//    UITableViewCell *swipedCell  = [self.tableView cellForRowAtIndexPath:swipedIndexPath];
    
    //Your own code...
    [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:swipedIndexPath];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    // Need to invoke popover from here
    if (tableView == self.tableView) {
        self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
    } else {
        self.activeProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }
    
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
    
//    NSString *placeText = nil;
//    if (self.lastSelected == categoryMode) {
//        // do something
//        placeText = @"Enter category name";
//    } else {
//        // do something else
//        placeText = @"Enter project name";
//    }
//    self.searchBar.placeholder = placeText;
    
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
            NSManagedObjectContext *context = [[CoreData sharedModel:self] managedObjectContext];
            [context deleteObject:[self.fetchedProjectsController objectAtIndexPath:indexPath]];
            
            // Save the context.
            NSError *error = [[NSError alloc] init];
            @try {
                if (![context save:&error]){
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
        if (self.activeProject) {
            [self.activeProject.managedObjectContext save:nil];
            [self sendTimerStopNotification];
        }
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

-(NSFetchedResultsController *)fetchedProjectsController{
    NSFetchedResultsController *retvalue;
    if (_fetchedProjectsController != nil) {
        retvalue = _fetchedProjectsController;
    } else {
        NSManagedObjectContext *context = [[CoreData sharedModel:self] managedObjectContext];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                  inManagedObjectContext:context];
        [self.request setEntity:entity];
        [self.request setFetchBatchSize:20];
        
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"active" ascending:NO];
        NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
        NSSortDescriptor *endDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateFinish" ascending:YES];
        NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"projectName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, completeDescriptor, endDateDescriptor, nameDescriptor, nil];
        [self.request setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
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
            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
//            break;
    }
}

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
    
    BOOL completeVal = [newProject.complete boolValue];
    BOOL activeVal = [newProject.active boolValue];
    
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
    
    if ([cell isKindOfClass:[ProjectCell class]]) {
        ProjectCell *projectCell = (ProjectCell *)cell;
        
        projectCell.statusIndicator.progress = [newProject.remainingHours floatValue];
        NSTimeInterval interval = [newProject.dateFinish timeIntervalSinceDate:[NSDate date]];
        
        if ( [newProject.isOverDue boolValue]){
            projectCell.statusIndicator.progressTintColor = [UIColor redColor];
        } else if (projectCell.statusIndicator.progress < 0.8f && interval < 84600 ) {
            projectCell.statusIndicator.progressTintColor = [UIColor yellowColor];
        } else  {
            projectCell.statusIndicator.progressTintColor = [UIColor greenColor];
        }
        if ( completeVal == NO & activeVal == NO){
            projectCell.statusIndicator.hidden = YES;
        } else {
            projectCell.statusIndicator.hidden = NO;
        }
    }
    
    NSString *caption;
    if (completeVal == NO & activeVal == YES) {
        caption = [[NSString alloc] initWithFormat:@"Target date: %@", endDate];
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == NO){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
    } else if ( completeVal == NO & activeVal == NO){
        caption = @"Inactive";
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == YES){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
    } else {
        caption = [[NSString alloc] initWithFormat:@"Should finish: %@", endDate];
        cell.imageView.image = nil;
    }
    
    // Set detail text color
    UIColor *textColor = nil;
    if (completeVal == YES) {
        textColor = kGreenColor;
    } else if ([newProject.isOverDue boolValue] == YES ) {
        textColor = [UIColor redColor];
    } else {
        textColor = [UIColor darkGrayColor];
    }
    cell.detailTextLabel.textColor = textColor;
    
    if (!self.activeProject && self.lastProjectID) {
        if ([self.lastProjectID isEqualToString:newProject.projectUUID]) {
            self.activeProject = newProject;
        }
    }
    
    if (newProject == self.activeProject) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    UIColor *projectColor = [newProject.projectPriority getCategoryColor];
    if (!projectColor) projectColor = [UIColor whiteColor];
    UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, kRowHeight)];
    catColor.backgroundColor = projectColor;
    catColor.layer.cornerRadius = 0;
    catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    catColor.layer.borderWidth = .5;
    [cell addSubview:catColor];
    
    cell.detailTextLabel.text = caption;
}

- (IBAction)insertNewObject:(UIButton *)sender
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

#pragma mark - Accessors
-(CCSettingsControl *)systemSettings{
    if (_systemSettings == nil) {
        _systemSettings = [[CCSettingsControl alloc] init];
    }
    return _systemSettings;
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

-(CCRecentTaskViewController *)recentListController{
    if (_recentListController == nil) {
        _recentListController = [self.storyboard instantiateViewControllerWithIdentifier:@"recentTasks"];
    }
    return _recentListController;
}

-(CCHotListViewController *)hotListController{
    if (_hotListController == nil) {
        _hotListController = [self.storyboard instantiateViewControllerWithIdentifier:@"hotListView"];
    }
    return _hotListController;
}

-(CCiPhoneDetailViewController *)detailController{
    if (_detailController == nil) {
        _detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"detailViewController"];
    }
    return _detailController;
}

@end
