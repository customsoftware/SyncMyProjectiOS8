//
//  CCMasterViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 _Ken Cluff. All rights reserved.
//
#define START_INDEX [NSIndexPath indexPathForRow:0 inSection:0]
#define END_INDEX [NSIndexPath indexPathForRow:1 inSection:0]
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]

#define kStartNotification  @"ProjectTimerStartNotification"
#define kStopNotification   @"ProjectTimerStopNotification"
#define kSearchState        @"searchMode"

#import "RatingReminder.h"
#import "CCMasterViewController.h"
#import "CCDetailViewController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCHotListViewController.h"
#import "CCPrintNotesRender.h"
#import "CCNewProjectViewController.h"
#import "CCInitializer.h"
#import "iCloudStarterProtocol.h"

typedef enum kfilterModes{
    allProjectsMode,
    activeProjectsMode,
    openProjectsMode,
    recentListMode,
    hotListMode
} kFilterModes;

@interface CCMasterViewController () <iCloudStarterProtocol>
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView;

@property (strong, nonatomic) CCGeneralCloser *closer;
@property (strong, nonatomic) CCMainTaskViewController *mainTaskController;
@property (strong, nonatomic) Project *activeProject;
@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSPredicate *activePredicate;
@property (strong, nonatomic) NSPredicate *openPredicate;
@property (strong, nonatomic) CCHotListViewController *hotListController;
@property NSInteger lastSelected;
@property (strong, nonatomic) NSMutableArray *filteredProjects;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@property (nonatomic) BOOL notInSearchMode;
@property (strong, nonatomic) RatingReminder * reminder;
@property (strong, nonatomic) NSString *lastProjectID;

@end

@implementation CCMasterViewController

#pragma mark - View lifecycle

- (void)awakeFromNib
{
    // self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.detailViewController = (CCDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Set up the search controller
    self.searchDisplayController.delegate = self;
    self.projectTimer = [[CCProjectTimer alloc] init];
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [application registeriCloudDelegate:self];
    
    // Set up swipe to see tasks
    // Add swipe gesture recognizer to default, unfiltered table view
    UISwipeGestureRecognizer *showExtrasSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    showExtrasSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:showExtrasSwipe];
    
    // Set up swipe to add projects
    self.swiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(insertNewObject:)];
    [self.swiper setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.navigationController.navigationBar addGestureRecognizer:self.swiper];
}

-(void)viewWillAppear:(BOOL)animated{
    NSString *enableNotification = @"EnableControlsNotification";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableControls) name:enableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMinimumRecordSet) name:kAppString object:nil];
    
    if (self.hotListController.projectTimer != nil) {
        [self.hotListController.projectTimer releaseTimer];
        self.hotListController.selectedIndex = nil;
    }
    
    if (self.activeProject != nil ){
        [self sendTimerStartNotificationForProject];
        if (self.activeProject == self.detailViewController.project) {
            self.activeProject.projectNotes = self.detailViewController.projectNotes.text;
            [self updateDetailControllerForIndexPath:self.controllingCellIndex inTable:self.tableView];
        } else {
            [self updateDetailControllerForIndexPath:self.controllingCellIndex inTable:self.tableView];
        }
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.lastSelected = [defaults integerForKey:kProjectFilterStatus];
        self.filterSegmentControl.selectedSegmentIndex = self.lastSelected;
        [self filterActions:self.filterSegmentControl];
    }
    self.swiper.enabled = YES;
    [self cleanCheckMarks:self.tableView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.activeProject != nil) {
        [self enableControls];
        [self sendTimerStartNotificationForProject];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.lastProjectID = [defaults objectForKey:kSelectedProject];
//        [self.tableView reloadData];
    }
//        for (Project *project in [self.fetchedProjectsController fetchedObjects]) {
//            if ([project.projectUUID isEqualToString:tempProject]) {
//                NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:project];
//                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//                [self updateDetailControllerForIndexPath:indexPath inTable:self.tableView];
//                break;
//            }
//        }
//    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] setBool:self.notInSearchMode forKey:kSearchState];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.swiper.enabled = NO;
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - IBActions
-(IBAction)filterActions:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == hotListMode){
        self.hotListController.projectDetailController = self.detailViewController;
        [self.navigationController pushViewController:self.hotListController animated:YES];
        sender.selectedSegmentIndex = self.lastSelected;
        [self sendTimerStopNotification];
    } else if (sender.selectedSegmentIndex == recentListMode){
//        [self.navigationController pushViewController:self.recentListController animated:YES];
        sender.selectedSegmentIndex = self.lastSelected;
        [self sendTimerStopNotification];
    } else {
        self.lastSelected = sender.selectedSegmentIndex;
        [[NSUserDefaults standardUserDefaults] setInteger:self.lastSelected forKey:kProjectFilterStatus];
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
        
        NSIndexPath *indexPath = nil;
        for (Project *project in self.fetchedProjectsController.fetchedObjects ) {
            if (self.activeProject == project) {
                indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
                break;
           }
        }
        
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }
}

-(IBAction)actionButton:(UIBarButtonItem *)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Close Projects" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"This Week", @"Yesterday", @"All Active", nil];
    actionSheet.tag = 1;
    [actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
}

#pragma mark - Popover Controls
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    NSIndexPath *indexPath = [self.fetchedProjectsController indexPathForObject:self.activeProject];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)respondToiCloudUpdate {
    [self.fetchedProjectsController performFetch:nil];
    [self.tableView reloadData];
    [self cleanCheckMarks:self.tableView];
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
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
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

- (void)sendOutput{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Send Email" otherButtonTitles:@"Print Report", nil];
    sheet.tag = 2;
    [sheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
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
            Project *newProject = [CoreData createProjectWithName:[alertView textFieldAtIndex:0].text];
            newProject.dateStart = newProject.dateCreated;
//            newProject.projectNotes = [[NSString alloc] initWithFormat:@"Enter notes for %@ project here", newProject.projectName];
            [[CoreData sharedModel:self] saveContext];
        }
    }
}

-(void)releaseLogger{
    self.logger = nil;
}

#pragma mark - Helper
-(void)sendTimerStartNotificationForProject{
    NSDictionary *projectDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:self.activeProject, @"Project", nil];
    NSNotification *startTimer = [NSNotification notificationWithName:kStartNotification object:nil userInfo:projectDictionary];
    [[NSNotificationCenter defaultCenter] postNotification:startTimer];
}

-(void)sendTimerStopNotification{
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
}

- (void)updateMinimumRecordSet {
//    self.inICloudMode = YES;
}

- (void)cleanCheckMarks:(UITableView *) tableView {
    for (int row = 0; row < [tableView numberOfRowsInSection:0]; row++) {
        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:0];
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:cellPath];
        //do stuff with 'cell'
        if (cell == self.controllingCell) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
    }
}


#pragma mark - Public functionality
-(void)setFontForDisplay{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    CGFloat fontSize = [defaults integerForKey:kFontSize];
    UIFont *displayFont = [UIFont fontWithName:fontFamily size:fontSize];
    self.detailViewController.projectNotes.font = displayFont;
}

-(void)setDisplayBackGroundColor{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat alpha = [defaults floatForKey:kSaturation];
    CGFloat red = [defaults floatForKey:kRedNameKey];
    CGFloat blue = [defaults floatForKey:kBlueNameKey];
    CGFloat green = [defaults floatForKey:kGreenNameKey];
    UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    self.detailViewController.projectNotes.backgroundColor = newColor;
}

-(Project *)getActiveProject{
    return self.activeProject;
}

-(void)enableControls{
    self.detailViewController.showDeliverables.enabled = YES;
    self.detailViewController.showCalendar.enabled = YES;
    self.detailViewController.showTimers.enabled = YES;
    self.detailViewController.showTaskChart.enabled = YES;
}

#pragma mark - Table Controls
-(void)updateDetailControllerForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView{
    [self.detailViewController.projectNotes resignFirstResponder];
    if (tableView == self.tableView) {
        if (self.fetchedProjectsController.fetchedObjects.count >= indexPath.row) {
            self.activeProject = [self.fetchedProjectsController objectAtIndexPath:indexPath];
        } else {
            self.activeProject = nil;
            self.controllingCellIndex = nil;
        }
    } else {
        self.activeProject = [self.filteredProjects objectAtIndex:indexPath.row];
    }
    self.detailViewController.project = self.activeProject;
    self.detailViewController.controllingCellIndex = indexPath;
    
    [self enableControls];
    [self sendTimerStopNotification];
    [self sendTimerStartNotificationForProject];
    self.controllingCellIndex = indexPath;
    self.controllingCell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *noteText = nil;
    NSString *titleText = nil;
    if (self.activeProject) {
        [self.activeProject.managedObjectContext save:nil];
        titleText = [NSString stringWithFormat:@"%@: Notes", self.activeProject.projectName];
        if (self.activeProject.projectNotes) {
            noteText = self.activeProject.projectNotes;
        } else {
            noteText = [NSString stringWithFormat:@"Enter notes for %@ project here", self.activeProject.projectName];
        }
    } else {
        noteText = @"Select a project";
        titleText = @"Notes";
    }
    self.detailViewController.projectNotes.text = noteText;
    self.detailViewController.title = titleText;
}

- (void)swipeRight:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:location];
    [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:swipedIndexPath];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    // Need to invoke popover from here
    [self resignFirstResponder];
    [self enableControls];
    [self updateDetailControllerForIndexPath:indexPath inTable:tableView];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
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
            [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:[self.fetchedProjectsController objectAtIndexPath:indexPath]];
            
            // Save the context.
            NSError *error = [[NSError alloc] init];
            @try {
                if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
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
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateDetailControllerForIndexPath:indexPath inTable:tableView];
    [self cleanCheckMarks:tableView];

}

#pragma mark - Fetched results controller
-(void)persistentStoreDidChange{
    NSError *error = nil;
    [self.fetchedProjectsController performFetch:&error];
    [self.tableView reloadData];
    self.activeProject = [[self.fetchedProjectsController fetchedObjects] objectAtIndex:self.lastSelected];
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
    CoreData *sharedModel = [CoreData sharedModel:nil];
    if (sharedModel.projectFRC != nil) {
        retvalue = sharedModel.projectFRC;
    } else {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                  inManagedObjectContext:sharedModel.managedObjectContext];
        [self.request setEntity:entity];
        [self.request setFetchBatchSize:20];
        
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"active" ascending:NO];
        NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
        NSSortDescriptor *endDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateFinish" ascending:YES];
        NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"projectName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, completeDescriptor, endDateDescriptor, nameDescriptor, nil];
        [self.request setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
        aFetchedResultsController.delegate = self;
        
        sharedModel.projectFRC = aFetchedResultsController;
        
        NSError *error = nil;
        @try {
            if(![sharedModel.projectFRC performFetch:&error]){
                self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.logger releaseLogger];
            }
        }
        @catch (NSException *exception) {
            self.logger = [[CCErrorLogger alloc] initWithErrorString:exception.reason andDelegate:self];
            [self.logger releaseLogger];
        }
        
        retvalue = sharedModel.projectFRC;
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
    
    NSString *caption;
    if (completeVal == NO & activeVal == YES) {
        caption = [[NSString alloc] initWithFormat:@"Target date: %@", endDate];
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == NO){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
        cell.detailTextLabel.textColor = kGreenColor;
    } else if ( completeVal == NO & activeVal == NO){
        caption = [[NSString alloc] initWithFormat:@"Should start: %@", startDate];
        cell.imageView.image = nil;
    } else if ( completeVal == YES & activeVal == YES){
        caption = [[NSString alloc] initWithFormat:@"Completed as of: %@", endDate];
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
        cell.detailTextLabel.textColor = kGreenColor;
    } else {
        caption = [[NSString alloc] initWithFormat:@"Should finish: %@", endDate];
        cell.imageView.image = nil;
    }

    UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 44)];
    catColor.backgroundColor = [newProject.projectPriority getCategoryColor];
    catColor.layer.cornerRadius = 0;
    catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    catColor.layer.borderWidth = .5;
    [cell addSubview:catColor];
    
    if (newProject == self.activeProject) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    cell.detailTextLabel.text = caption;
}

- (IBAction)insertNewObject:(UIBarButtonItem *)sender
{
    CCNewProjectViewController *newProject = [self.storyboard instantiateViewControllerWithIdentifier:@"newProjectName"];
    newProject.preferredContentSize = CGSizeMake(400, 175);
    newProject.popoverDelegate = self;
    self.projectPopover = [[UIPopoverController alloc] initWithContentViewController:newProject];
    NSMutableArray *passThrough = [[NSMutableArray alloc] init];
    [passThrough addObject:self.view];
    [passThrough addObject:self.detailViewController.view];
    self.projectPopover.passthroughViews = passThrough;
    [self.projectPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - <CCPopoverControllerDelegate>
- (void)cancelPopover{
    [self.detailViewController.view endEditing:YES];
    [self.view endEditing:YES];
    [self.projectPopover dismissPopoverAnimated:YES];
}

- (void)savePopoverData{
    [self.detailViewController.view endEditing:YES];
    [self.view endEditing:YES];
    CCNewProjectViewController *newProjectController = (CCNewProjectViewController *)self.projectPopover.contentViewController;

    Project *newProject = [CoreData createProjectWithName:newProjectController.projectName.text];
    newProject.projectName = newProjectController.projectName.text;
    newProject.dateStart = newProject.dateCreated;
    newProject.active = [NSNumber numberWithBool:YES];
    
    [newProject.managedObjectContext save:nil];
    NSIndexPath *indexPath = nil;
    
    // Position the active cell on the new project
    for (Project *project in [self.fetchedProjectsController fetchedObjects]) {
        if ([project.projectUUID isEqualToString:newProject.projectUUID]) {
            indexPath = [self.fetchedProjectsController indexPathForObject:project];
            break;
        }
    }
    
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self updateDetailControllerForIndexPath:indexPath inTable:self.tableView];
    }
    [self.projectPopover dismissPopoverAnimated:YES];
}

#pragma mark - Lazy getters
-(CCMainTaskViewController *)mainTaskController{
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

- (void)viewDidUnload {
    [self setFilterSegmentControl:nil];
    [super viewDidUnload];
}
@end
