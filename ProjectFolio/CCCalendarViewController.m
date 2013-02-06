//
//  CCTimeViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import "CCCalendarViewController.h"

@interface CCCalendarViewController ()
@property (strong, nonatomic) CCErrorLogger *logger;

@end

@implementation CCCalendarViewController

@synthesize project = _project;
@synthesize meeting = _meeting;
@synthesize selectedIndexPath = _selectedIndexPath;
@synthesize childController = _childController;
@synthesize calendarController = _calendarController;
@synthesize selectedCell = _selectedCell;
@synthesize endDateFormatter = _endDateFormatter;
@synthesize dateFormatter = _dateFormatter;
@synthesize logger = _logger;

#pragma mark - IBActions

-(IBAction)insertEvent{
    Calendar *newMeeting = [NSEntityDescription insertNewObjectForEntityForName:@"Calendar" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    if (newMeeting != nil) {
        newMeeting.event = @"New meeting";
        newMeeting.start = [NSDate date];
        newMeeting.stop = [NSDate date];
        newMeeting.notes = @"meetings notes";
        newMeeting.repeat = [NSNumber numberWithInt:0];
       
        [self.project addProjectCalendarObject:newMeeting];
        [newMeeting addCalendarProjectObject:self.project];
        
        self.meeting = newMeeting;
    //[self calendarEditor:self.tableView rowIndex:nil];
    [self showNewMeetingDetails:self.tableView rowIndex:nil];
    } else {
        //NSLog(@"failed to create meeting");
    }

}

-(void)releaseLogger{
    self.logger = nil;
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

-(void)viewWillAppear:(BOOL)animated{
    if ([self.meeting.event isEqualToString:@"Delete me"]) {
        [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
        
        // Save the context.
        NSError *error = [[NSError alloc] init];
        @try {
            if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
                self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.logger releaseLogger];
            }
        }
        @catch (NSException *exception) {
            self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.logger releaseLogger];
        }
    }
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    self.endDateFormatter = [[NSDateFormatter alloc] init];
    [self.endDateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [self.endDateFormatter setDateStyle:NSDateFormatterNoStyle];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.project = nil;
    self.selectedIndexPath = nil;
    self.childController = nil;
    self.selectedCell = nil;
    self.meeting = nil;
    self.dateFormatter = nil;
    self.endDateFormatter = nil;
    self.logger = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Meeting planner
-(void)showMeetingDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    CCAppDelegate *application = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    // Find the event based upon the event id in the event
    EKEvent *event = [application.eventStore eventWithIdentifier:self.meeting.eventID];
    if (event != nil) {
        self.calendarController.event = event;
        self.calendarController.delegate = self;
        self.calendarController.editing = YES;
        CGRect rect = self.view.frame;
        self.calendarController.contentSizeForViewInPopover = rect.size;
        [self.navigationController pushViewController:self.calendarController animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Deleted Event" message:@"The meeting has been deleted elsewhere" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
        
        // Save the context.
        // Save the context.
        NSError *error = [[NSError alloc] init];
        @try {
            if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
                self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.logger releaseLogger];
            }
        }
        @catch (NSException *exception) {
            self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.logger releaseLogger];
        }
        @finally {
            [tableView deleteRowsAtIndexPaths:[[NSArray alloc] initWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView reloadData];
    }

}

-(void)showNewMeetingDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    CCAppDelegate *application = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
    EKEvent *event = [EKEvent eventWithEventStore:application.eventStore];
    self.childController.eventStore = application.eventStore;
    self.childController.event = event;
    self.childController.editViewDelegate = self;
    self.childController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.childController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    [self.navigationController presentModalViewController:self.childController animated:YES];
}

-(void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action{
    switch (action) {
        case EKEventEditViewActionCanceled:
            //NSLog(@"cancelled");
            [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        case EKEventEditViewActionSaved:
            //NSLog(@"Here we save the calendar event in our local table too");
            self.meeting.start = self.childController.event.startDate;
            self.meeting.stop = self.childController.event.endDate;
            self.meeting.notes = self.childController.event.notes;
            self.meeting.event = self.childController.event.title;
            self.meeting.eventID = self.childController.event.eventIdentifier;
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        case EKEventEditViewActionDeleted:
            //NSLog(@"Here we remove the calendar");
            [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
    // Save the context.
    NSError *error = [[NSError alloc] init];
    @try {
        if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
            self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.logger releaseLogger];
        }
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
        [self.logger releaseLogger];
    }
    
    [self.tableView reloadData];
}


-(void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action{
    switch (action) {
        case EKEventViewActionResponded:
            //NSLog(@"Responded to the edit");
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        case EKEventViewActionDone:
            //NSLog(@"Here we save the calendar event in our local table too");
            self.meeting.start = self.childController.event.startDate;
            self.meeting.stop = self.childController.event.endDate;
            self.meeting.notes = self.childController.event.notes;
            self.meeting.event = self.childController.event.title;
            self.meeting.eventID = self.childController.event.eventIdentifier;
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        case EKEventViewActionDeleted:
            [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
            [self.navigationController dismissModalViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
    // Save the context.
    NSError *error = [[NSError alloc] init];
    @try {
        if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
            self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.logger releaseLogger];
        }
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
        [self.logger releaseLogger];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *meetings = [self.project.projectCalendar allObjects];
    return [meetings count];
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    Calendar *newMeeting = [[self.project.projectCalendar allObjects] objectAtIndex:[indexPath row]];
    cell.textLabel.text = newMeeting.event;
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@",
                                 [self.dateFormatter stringFromDate:newMeeting.start]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"calendarCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
     // Delete the row from the data source
         self.meeting = [[self.project.projectCalendar allObjects] objectAtIndex:[indexPath row]];
         [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.meeting];
         
         // Save the context.
         NSError *error = [[NSError alloc] init];
         @try {
             if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
                 self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                 [self.logger releaseLogger];
             }
         }
         @catch (NSException *exception) {
             self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
             [self.logger releaseLogger];
         }
         @finally {
             [tableView deleteRowsAtIndexPaths:[[NSArray alloc] initWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
         }
     }
     else if (editingStyle == UITableViewCellEditingStyleInsert) {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         // NSLog(@"Insert called");
     }
 }
 

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
    self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectedIndexPath = indexPath;
    self.meeting = [[self.project.projectCalendar allObjects] objectAtIndex:[indexPath row]];
    [self showMeetingDetails:tableView rowIndex:indexPath];
}

#pragma mark - Lazy getters
-(EKEventEditViewController *)childController{
    if (_childController == nil) {
        _childController = [[EKEventEditViewController alloc] init];
    }
    return _childController;
}

-(EKEventViewController *)calendarController{
    if (_calendarController == nil) {
        _calendarController = [[EKEventViewController alloc] init];
    }
    return _calendarController;
}

@end
