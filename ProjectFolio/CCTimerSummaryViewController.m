//
//  CCTimerSummaryViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 8/14/12.
//
//

#import "CCTimerSummaryViewController.h"

@interface CCTimerSummaryViewController ()

@property (strong, nonatomic) NSNumberFormatter *costFormatter;
@property (strong, nonatomic) NSNumberFormatter *hourFormatter;
@property double billableAmount;
@property CGRect originalSize;
@property (strong, nonatomic) CCEmailer *emailer;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *timerFRC;
@property (strong, nonatomic) Project *controllingProject;
@property (strong, nonatomic) NSMutableArray *billableTimers;
@property (strong, nonatomic) CCTimeViewController *timerDetails;
@property NSInteger selectedIndex;

@end

@implementation CCTimerSummaryViewController

#pragma mark - Date methods
-(NSDate *)yesterday{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc] init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:components.day-1];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)lastWeek{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *yesterday = [self yesterday];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:yesterday];
    [components setDay:components.day-7];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)lastMonth{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc]init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:1];
    [components setMonth:components.month-1];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)endOfLastMonth{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc]init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:-1];
    [components setMonth:components.month];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

#pragma mark - Helpers
- (void)compressBilledEvents {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WorkTime"];
        NSSortDescriptor *sortByProjectUUID = [[NSSortDescriptor alloc] initWithKey:@"workProject.projectUUID" ascending:YES];
        NSSortDescriptor *sortByTaskUUID = [[NSSortDescriptor alloc] initWithKey:@"workTask.taskUUID" ascending:YES];
        [request setSortDescriptors:@[sortByProjectUUID,sortByTaskUUID]];
        NSPredicate *timerPredicate = [NSPredicate predicateWithFormat:@"(workProject.projectName == %@) AND ( billed == 1 )", self.controllingProject.projectName];
        [request setPredicate:timerPredicate];
        
        // Since this is on a background thread, create a manage object context for this thread
    NSManagedObjectContext *context = [[CoreData sharedModel:nil] managedObjectContext];
//        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        context.persistentStoreCoordinator = [[CoreData sharedModel:nil]persistentStoreCoordinator];
    
        NSFetchedResultsController *eventsFRC =
        [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                            managedObjectContext:context
                                              sectionNameKeyPath:nil
                                                       cacheName:nil];
        
        [eventsFRC performFetch:nil];
        NSArray *fetchedEvents = [eventsFRC fetchedObjects];
        NSString *currentProjectUUID = @"NotHere";
        NSString *currentTaskUUID = @"NotHere";
        NSString *currentDay = @"Not Set";
        WorkTime *compressedTime = nil;
        float currentInterval = 0;
        for (WorkTime *event in fetchedEvents) {
            // Always get the interval
            NSTimeInterval elapseTime = [event.end timeIntervalSinceDate:event.start]; //3600;
//            NSLog(@"Raw elapse: %f", elapseTime);
            //elapseTime = round(elapseTime*1000)/1000;
            
            if ([event.workTask.taskUUID isEqualToString:currentTaskUUID] &&
                [event.workProject.projectUUID isEqualToString:currentProjectUUID] &&
                [event.taskDay isEqualToString:currentDay]) {
                currentInterval = currentInterval + elapseTime;
//                NSLog(@"a Interval: %f", currentInterval);
//                compressedTime.end = [compressedTime.start dateByAddingTimeInterval:currentInterval];
            } else if ( event.workTask.taskUUID == nil &&
                       [event.workProject.projectUUID isEqualToString:currentProjectUUID] &&
                       [event.taskDay isEqualToString:currentDay]) {
                currentInterval = currentInterval + elapseTime;
//                NSLog(@"b Interval: %f", currentInterval);
//                compressedTime.end = [compressedTime.start dateByAddingTimeInterval:currentInterval];
            } else {
                // Close out the old one and create a new one
                if (compressedTime) {
                    // Save
                    compressedTime.start = event.start;
                    compressedTime.end = [compressedTime.start dateByAddingTimeInterval:currentInterval];
                    [compressedTime.managedObjectContext save:nil];
                    compressedTime = nil;
                }
                
                compressedTime = [CoreData createNewTimerForProject:event.workProject andTask:event.workTask];
                
//                compressedTime = [CoreData createNewTimerForProject:event.workProject andTask:event.workTask];
                //compressedTime.start = event.start;
                //compressedTime.end = event.end;
                currentInterval = elapseTime;
                compressedTime.timerUUID = [[CoreData sharedModel:nil] getUUID];
                compressedTime.billed = [NSNumber numberWithBool:YES];
                currentProjectUUID = event.workProject.projectUUID;
                currentTaskUUID = event.workTask.taskUUID;
                currentDay = event.taskDay;
                //
            }
            [context deleteObject:event];
        }
        [context save:nil];
//    });
}

#pragma mark - Delegate actions
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            // Do nothing
            break;
            
        case 1:
            // Compress
            [self compressBilledEvents];
            break;
            
        default:
            break;
    }
}

-(void)didFinishWithError:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didFinishWithResult:(MFMailComposeResult)result{
    // We'll need to roll back some changes here if the report was cancelled.
    if (result == MFMailComposeResultCancelled || result == MFMailComposeResultFailed) {
        // NSLog(@"Don't do anything");
    } else {
        // This goes out of this if statement once printing is working
        if ([self.markBilled isOn]) {
            for (WorkTime *time in self.billableTimers) {
                if ( time.start != nil && time.end != nil){
                    time.billed = [[NSNumber alloc] initWithBool:YES];
                } else if ( time.end == nil && [self.billableTimers indexOfObject:time] > 0){
                    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:time];
                }
            }
            [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
            
            [self viewWillAppear:YES];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions
-(IBAction)showDetails:(UISegmentedControl *)sender{
    self.timerDetails = [self.storyboard instantiateViewControllerWithIdentifier:@"timeDetails"];
    self.timerDetails.project = self.controllingProject;
    self.timerDetails.timeSelectorDelegate = self;
    self.selectedIndex = sender.selectedSegmentIndex;
    [self.navigationController pushViewController:self.timerDetails animated:YES];
}

-(NSInteger)getSelectedSegment{
    return self.selectedIndex;
}

-(void)setCurrentBillingValues:(NSInteger)index{
    double reportableTime = 0;
    NSDate *startRange = nil;
    NSDate *endRange = nil;
    self.billableTimers = [[NSMutableArray alloc] init];
    // NSLog(@"Number of timers: %d", [self.timerFRC.fetchedObjects count]);
    for (WorkTime *time in [self.timerFRC fetchedObjects]) {
        NSTimeInterval elapseTime = [time.end timeIntervalSinceDate:time.start];
        if ([time.billed integerValue] == UNBILLED) {
            switch (index) {
                case ALL_UNBILLED:
                    reportableTime = reportableTime + elapseTime;
                    [self.billableTimers addObject:time];
                    break;
                    
                case YESTERDAY_UNBILLED:
                    // Yesterday, means all events which started the day before today
                    startRange = [self yesterday];
                    endRange = [[NSDate alloc] initWithTimeInterval:ONE_DAY sinceDate:startRange];
                    if ([time.start timeIntervalSinceDate:startRange] >= 0 && [time.start timeIntervalSinceDate:endRange] < 0 ) {
                        [self.billableTimers addObject:time];
                        reportableTime = reportableTime + elapseTime;
                    }
                    break;
                    
                case LAST_WEEK_UNBILLED:
                    // This means everything within the preceding 7 days
                    startRange = [self lastWeek];
                    endRange = [[NSDate alloc] initWithTimeInterval:ONE_WEEK sinceDate:startRange];
                    if ([time.start timeIntervalSinceDate:startRange] >= 0 && [time.start timeIntervalSinceDate:endRange] < 0 ) {
                        [self.billableTimers addObject:time];
                        reportableTime = reportableTime + elapseTime;
                    }
                    break;
                    
                case LAST_MONTH_UNBILLED:
                    // This means everything within the preceding calendar month
                    startRange = [self lastMonth];
                    endRange = [self endOfLastMonth];
                    if ([time.start timeIntervalSinceDate:startRange] >= 0 && [time.start timeIntervalSinceDate:endRange] < 0 ) {
                        [self.billableTimers addObject:time];
                        reportableTime = reportableTime + elapseTime;
                    }
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    // NSLog(@"Billable events: %d", [self.billableTimers count]);
    
    self.billableAmount = round(reportableTime/36)/100;
    self.reportableTime.text = [[NSString alloc] initWithFormat:@"%@ hours", [self.hourFormatter stringFromNumber:[[NSNumber alloc] initWithFloat:self.billableAmount ]]];


    if ([self.time.workProject.hourlyRate doubleValue] != 0) {
        double billAmount = [self.time.workProject.hourlyRate doubleValue] * self.billableAmount;
        self.billingAmount.text = [self.costFormatter stringFromNumber:[[NSNumber alloc] initWithFloat:billAmount]];
    } else {
        self.billingAmount.text = @"Bill rate not set";
    }
}

-(IBAction)setFilterRange:(UISegmentedControl *)sender{
    [self setCurrentBillingValues:sender.selectedSegmentIndex];
}

#pragma mark - Action sheet
-(void)showActionSheet{
    UIActionSheet *outPutter = [[UIActionSheet alloc] initWithTitle:@"Close Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Just Close" otherButtonTitles: @"Send Report and Close", nil];
    
    [outPutter showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSString *billingString = [[NSString alloc]
                               initWithFormat:@"Billed Hours: %@. At Billing Rate: %@/hour. Total Value: %@.",
                               [self.hourFormatter stringFromNumber:[[NSNumber alloc] initWithFloat:self.billableAmount]],
                               [self.costFormatter stringFromNumber:self.time.workProject.hourlyRate],
                               [self.costFormatter stringFromNumber:[[NSNumber alloc]
                                                                     initWithFloat:([self.time.workProject.hourlyRate doubleValue]* self.billableAmount)]]];
    
    if (buttonIndex == 2) {
        // Do nothing
    } else if (buttonIndex == 1) {
        self.emailer = [[CCEmailer alloc] init];
        self.emailer.emailDelegate = self;
        
        self.emailer.subjectLine = @"Hours Billing Statement";
        self.emailer.messageText = billingString;
        self.emailer.useHTML = [NSNumber numberWithBool:YES];
        [self.emailer sendEmail];
        [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
        
    } else if (buttonIndex == 0){
        if ([self.markBilled isOn]) {
            for (WorkTime *time in self.billableTimers) {
                if ( time.start != nil && time.end != nil){
                    time.billed = [[NSNumber alloc] initWithBool:YES];
                } else if ( time.end == nil && [self.billableTimers indexOfObject:time] > 0){
                    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:time];
                }
            }
            
            [self viewWillAppear:YES];
        }
        
    } else if (buttonIndex == 3){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Compress Time" message:@"Do you want the billed time compressed into daily totals? This is not reversible." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"OK", nil];
         [alert show];
    }
    
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

-(void)viewWillAppear:(BOOL)animated{
    double totalBilled = 0;
    double totalUnBilled = 0;
    double remainingHours = 0;
    double remainingBudget = 0;
    self.controllingProject = [self.projectDelegate getActiveProject];
    // NSLog(@"Project: %@", self.controllingProject.projectName);
    NSPredicate *timerDelegate = [NSPredicate predicateWithFormat:@"workProject.projectName == %@", self.controllingProject.projectName];
    [self.fetchRequest setPredicate:timerDelegate];
    [self.timerFRC performFetch:nil];
    
    for (WorkTime *time in self.timerFRC.fetchedObjects)
    {
        NSTimeInterval elapseTime = [time.end timeIntervalSinceDate:time.start];
        if ([time.billed integerValue] == UNBILLED)
        {
            totalUnBilled = totalUnBilled + elapseTime;
        } else {
            totalBilled = totalBilled + elapseTime;
        }
        self.time = time;
    }
    
    totalUnBilled = round(totalUnBilled/36)/100;
    totalBilled = round(totalBilled/36)/100;
     
    self.totalProjectTime.text = [[NSString alloc] initWithFormat:@"%@ hours",
                                  [self.hourFormatter stringFromNumber:
                                  [[NSNumber alloc] initWithFloat:totalUnBilled + totalBilled ]]];
    self.billedTime.text = [[NSString alloc] initWithFormat:@"%@ hours",
                            [self.hourFormatter stringFromNumber:[[NSNumber alloc] initWithFloat:totalBilled ]]];
    self.unbilledTime.text = [[NSString alloc] initWithFormat:@"%@ hours",
                              [self.hourFormatter stringFromNumber:[[NSNumber alloc] initWithFloat:totalUnBilled]]];
    
    // Set hours to be billed
    [self setCurrentBillingValues:0];
    
    // Set Bill rate and Amount
    if ([self.time.workProject.hourlyRate doubleValue] != 0) {
        self.billRate.text = [[NSString alloc] initWithFormat:@"%@/hour", [self.costFormatter stringFromNumber:self.time.workProject.hourlyRate]];
    } else {
        self.billRate.text = @"Bill rate not set";
    }
    
    // Set remaining hours
    NSString *remainingHourText;
    if ([self.time.workProject.hourBudget doubleValue] > 0) {
        remainingHours = [self.time.workProject.hourBudget doubleValue];
        remainingHours = remainingHours - ( totalBilled + totalUnBilled);
        remainingHourText = [[NSString alloc] initWithFormat:@"%@ hours", [self.hourFormatter stringFromNumber:[[NSNumber alloc]initWithFloat:remainingHours]]];
    } else {
        remainingHourText = @"Hour budget not set";
    }
    self.remainingTime.text = remainingHourText;
    
    // Set remaining budget
    NSString *remainingBudgetText;
    if ([self.time.workProject.costBudget doubleValue] > 0 && [self.time.workProject.hourlyRate doubleValue] != 0) {
        remainingBudget = ( totalBilled + totalUnBilled) *[self.time.workProject.hourlyRate doubleValue];
        remainingBudget = [self.time.workProject.costBudget doubleValue] - remainingBudget;
        // NSLog(@"Billed time: %f", remainingBudget);
        remainingBudgetText = [[NSString alloc] initWithFormat:@"%@", [self.costFormatter stringFromNumber:[[NSNumber alloc]initWithFloat:remainingBudget]]];
    } else {
        remainingBudgetText = @"Budget not set";
    }
    self.remainingBudget.text = remainingBudgetText;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *allDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: allDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.timerFRC.delegate = self;
    self.timerFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
    
    self.hourFormatter = [[NSNumberFormatter alloc]init];
    [self.hourFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.hourFormatter setMinimumFractionDigits:2];
    
    self.costFormatter = [[NSNumberFormatter alloc]init];
    [self.costFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [self.costFormatter setMinimumFractionDigits:2];
    
    self.navigationItem.title = @"Summary of Time";
    UIBarButtonItem * printButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet)];
    self.navigationItem.rightBarButtonItem = printButton;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

@end