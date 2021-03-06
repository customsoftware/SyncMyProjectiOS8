//
//  CCGeneralCloser.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/6/12.
//
//

#import "CCGeneralCloser.h"
#import "CCDetailViewController.h"
#import "CCProjectTaskReport.h"

@interface CCGeneralCloser()
@property (strong, nonatomic) NSString *subjectLine;
@property (assign, nonatomic) CCDetailViewController *callingView;
@property (assign, nonatomic) CCiPhoneMasterViewController *callingViewiPhone;
@property (strong, nonatomic) NSMutableArray *projectResults;
@property (strong, nonatomic) NSMutableArray *dailyResults;
@property (strong, nonatomic) NSArray *billableResults;
@property NSInteger mode;

@end

@implementation CCGeneralCloser

#pragma mark - Life Cycle
-(void)viewDidLoad{
    [super viewDidLoad];
}

#pragma mark - Init Variations
-(CCGeneralCloser *)initForAllFor:(id)sender{
    CCGeneralCloser *newCloser = [super init];
    self.printDelegate = sender;
    self.mode = ALL_UNBILLED;
    self.subjectLine = @"Close all active projects";
    return newCloser;
}

-(CCGeneralCloser *)initForYesterdayFor:(id)sender{
    CCGeneralCloser *newCloser = [super init];
    self.printDelegate = sender;
    self.mode = YESTERDAY_UNBILLED;
    self.subjectLine = @"Close yesterday's projects";
    return newCloser;
}

-(CCGeneralCloser *)initWithLastWeekFor:(id)sender{
    CCGeneralCloser *newCloser = [super init];
    self.printDelegate = sender;
    self.mode = THIS_WEEK_UNBILLED;
    self.subjectLine = @"Close this week's projects";
    return newCloser;
}

#pragma mark - Build Message
-(NSDate *)yesterday{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [[NSDate alloc] init];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:today];
    [components setDay:components.day-1];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    // NSLog(@"Start: %@", [returnValue description]);
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

-(NSDate *)thisWeek{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *yesterday = [self yesterday];
    NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:yesterday];
    [components setDay:components.day-components.day+1];
    NSDate *returnValue = [gregorian dateFromComponents:components];
    return returnValue;
}

-(NSDate *)getStart{
    NSDate *startRange;
    switch (self.mode) {
        case YESTERDAY_UNBILLED:
            startRange = [self yesterday];
            break;
            
        case LAST_WEEK_UNBILLED:
            startRange = [self lastWeek];
            break;
            
        case THIS_WEEK_UNBILLED:
            startRange = [self thisWeek];
            break;
            
        default:
            startRange = nil;
            break;
    }
    return startRange;
}

-(NSDate *)getEnd{
    NSDate *endRange;
    switch (self.mode) {
        case YESTERDAY_UNBILLED:
            endRange = [[NSDate alloc] initWithTimeInterval:ONE_DAY sinceDate:[self getStart]];
            break;
            
        case LAST_WEEK_UNBILLED:
            endRange = [self yesterday];
            break;
            
        case THIS_WEEK_UNBILLED:
            endRange = [[NSDate alloc] initWithTimeInterval:ONE_DAY sinceDate:[self yesterday]];
            // NSLog(@"End: %@", [endRange description]);
            break;
            
        default:
            endRange = nil;
            break;
    }
    return endRange;
}


-(NSArray *)getBillableArray{
//    NSArray *testArray = [CCProjectTaskReport getReportGroupedByProjectTaskDateForDateRange:yesterdayMode fromDate:[NSDate date]];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *projectDescriptor = [[NSSortDescriptor alloc] initWithKey:@"workProject.projectName" ascending:YES];
    NSSortDescriptor *startDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:projectDescriptor, startDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    NSPredicate *completedPredicate = nil;
    if ([self getStart] != nil){
        completedPredicate = [NSPredicate predicateWithFormat:@"workProject.projectName != nil AND ( billed == nil OR billed == 0) AND start >= %@ AND start <= %@ AND workProject.billable = 1", [self getStart], [self getEnd]];
    } else {
        completedPredicate = [NSPredicate predicateWithFormat:@"workProject.projectName != nil AND ( billed == nil OR billed == 0 ) AND end != nil AND workProject.billable = 1"];
    }
    [self.fetchRequest setPredicate:completedPredicate];
    self.eventFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                        managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                          sectionNameKeyPath:nil
                                                                   cacheName:nil];
    NSError *requestError = nil;
    [self.eventFRC performFetch:&requestError];
    return [self.eventFRC fetchedObjects];
}

#pragma mark - Public API
-(void)billEvents{
    // NSLog(@"Well nuke'm here");
    for (WorkTime *event in self.billableResults) {
        event.billed = [NSNumber numberWithBool:YES];
    }
}

-(void)setMessage{
    if (self.subjectLine == nil) {
        self.subjectLine = @"Whoops";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:2];
    [numberFormatter setMinimumIntegerDigits:1];
    [numberFormatter setRoundingMode:NSNumberFormatterRoundUp];
    NSMutableString *messageString = [[NSMutableString alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *newProject = nil;
    NSString *oldProject = nil;
    NSString *newDate = nil;
    NSNumber *billRate = nil;
    NSString *oldDate = [[NSString alloc] initWithFormat:@"Who me???"];
    float currentInterval = 0;
    float projectInterval = 0;
    float totalInterval = 0;
    float totalInvoicedAmount = 0;
    
    self.billableResults = [self getBillableArray];
    for (WorkTime *event in self.billableResults) {
        // Get the building blocks
        NSTimeInterval elapseTime = [event.end timeIntervalSinceDate:event.start]/3600;
        elapseTime = round(elapseTime*1000)/1000;
        NSString *newString = nil;
        newProject = event.workProject.projectName;
        newDate = [dateFormatter stringFromDate:event.start];
        
        // Temmporary: use to see how we're doing
        if ( elapseTime > 0 && ![newProject isEqualToString:@"Who me???"]) {
            if ([newProject isEqualToString:oldProject]) {
                if ([newDate isEqualToString:oldDate]) {
                    // Update the daily and project counters
                    currentInterval = currentInterval + elapseTime;
                } else {
                    // Write the daily record
                    currentInterval = roundf(currentInterval * 100)/100;
                    newString = [[NSString alloc] initWithFormat:@"<TR><TD>Day: %@</TD><TD></TD><TD>Elapse time: %@</TD></TR>",
                                 oldDate,
                                 [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                    [messageString appendString:newString];
                    
                    // Update the project counter
                    projectInterval = projectInterval + currentInterval;
                    // This elapse time represents a new day, so increment it now
                    currentInterval = elapseTime;
                }
            }
            else {
                // Changing Project .. Write the last Day
                if (![oldDate isEqualToString:@"Who me???"]) {
                    if (self.mode != YESTERDAY_UNBILLED) {
                        currentInterval = roundf(currentInterval * 100)/100;
                        newString = [[NSString alloc] initWithFormat:@"<TR><TD>Day: %@</TD><TD></TD><TD>Elapse time: %@</TD></TR></TABLE>",
                                     oldDate,
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                        [messageString appendString:newString];
                        
                        [messageString appendString:[[NSString alloc] initWithFormat:@"___________________________________________________<br>"]];
                        
                        // Update the project counter
                        projectInterval = projectInterval + currentInterval;
                        projectInterval = roundf(projectInterval * 100)/100;
                        float totalBilledCost = projectInterval * [billRate floatValue];
                        totalInvoicedAmount = totalInvoicedAmount + totalBilledCost;
                        newString = [[NSString alloc] initWithFormat:@"<i>%@ Elapse time:</i> %@ Billed Cost: $%0.02f<p>",
                                     oldProject,
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:projectInterval]],
                                     totalBilledCost];
                        [messageString appendString:newString];
                        
                        newString = [[NSString alloc] initWithFormat:@"<p><b>Project: %@</b><TABLE>", newProject];
                        [messageString appendString:newString];
                        totalInterval = totalInterval + projectInterval;
                        
                    } else {
                        currentInterval = roundf(currentInterval * 100)/100;
                        newString = [[NSString alloc] initWithFormat:@"<TR><TD>Project:</TD><TD>%@</TD><TD>Day:</TD><TD>%@</TD><TD>Elapse time:</TD><TD>%@</TD></TR>",
                                     oldProject,
                                     oldDate,
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                        [messageString appendString:newString];
                        totalInterval = totalInterval + currentInterval;
                    }
                    
                } else if ( ![newProject isEqualToString:@"Who me???"]  && self.mode != YESTERDAY_UNBILLED){
                    
                    newString = [[NSString alloc] initWithFormat:@"<p><b>Project: %@</b><TABLE>", newProject];
                    [messageString appendString:newString];
                    //[messageString appendString:@"<p>"];
                } else if ( ![newProject isEqualToString:@"Who me???"]  && self.mode == YESTERDAY_UNBILLED){
                    newString = [[NSString alloc] initWithFormat:@"<TABLE>"];
                    [messageString appendString:newString];
                }
                // Reset the daily and project summaries
                currentInterval = elapseTime;
                projectInterval = 0;
            }
            // Get ready for the next Loop
            oldDate = newDate;
            oldProject = newProject;
            billRate = event.workProject.hourlyRate;
        }
    }
    
    if (currentInterval != 0) {
        if (![oldProject isEqualToString:@"Who me???"]) {
            if (self.mode != YESTERDAY_UNBILLED) {
                currentInterval = roundf(currentInterval * 100)/100;
                NSString *newString = [[NSString alloc] initWithFormat:@"<TR><TD>Day: %@</TD><TD></TD><TD>Elapse time: %@</TD></TR></TABLE>", oldDate,[numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                [messageString appendString:newString];
                
                [messageString appendString:[[NSString alloc] initWithFormat:@"___________________________________________________<br>"]];
                
                // Update the project counter
                projectInterval = projectInterval + currentInterval;
                projectInterval = roundf(projectInterval * 100)/100;
                float totalBilledCost = projectInterval * [billRate floatValue];
                totalInvoicedAmount = totalInvoicedAmount + totalBilledCost;
                newString = [[NSString alloc] initWithFormat:@"<i>%@ Elapse time:</i> %@ Billed Cost: $%0.02f<p>",
                             oldProject,
                             [numberFormatter stringFromNumber:[NSNumber numberWithFloat:projectInterval]],
                             totalBilledCost];
                [messageString appendString:newString];
                totalInterval = totalInterval + projectInterval;
                
            } else {
                
                NSString *newString = [[NSString alloc] initWithFormat:@"<TR><TD>Project:</TD><TD>%@</TD><TD>Day:</TD><TD>%@</TD><TD>Elapse time:</TD><TD>%@</TD></TR>",
                                       oldProject,
                                       oldDate,
                                       [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                [messageString appendString:newString];
                totalInterval = totalInterval + currentInterval;
                
                /*currentInterval = roundf(currentInterval * 100)/100;
                 NSString *newString = [[NSString alloc] initWithFormat:@"<TR><TD><b>%@</b>   </TD><TD>Elapse time: %@</TD></TR>", oldProject, [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                 [messageString appendString:newString];
                 totalInterval = totalInterval + currentInterval;*/
            }
            
        }
    }
    
    [messageString appendString:@"</TABLE><br>"];
    [messageString appendString:[[NSString alloc] initWithFormat:@"___________________________________________________<br>"]];
    [messageString appendString:[[NSString alloc] initWithFormat:@"___________________________________________________"]];
    
    NSString *newString = [[NSString alloc] initWithFormat:@"<p><b>Total Elapse time: %@  Total Invoiced Amount: %0.02f</b><p>", [numberFormatter stringFromNumber:[NSNumber numberWithFloat:totalInterval]], totalInvoicedAmount];
    [messageString appendString:newString];
    self.messageString = [NSString stringWithFormat:@"<font face=&quot;%@&quot;>%@</font.>",fontFamily, messageString];
    [self.printDelegate sendOutput];
}

- (void)emailMessage{
    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
    [self.mailComposer setSubject:self.subjectLine];
    [self.mailComposer setMessageBody:self.messageString isHTML:YES];
}

#pragma mark - Lazy Getter
-(MFMailComposeViewController *)mailComposer{
    if (_mailComposer == nil) {
        _mailComposer = [[MFMailComposeViewController alloc] init];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _mailComposer.mailComposeDelegate = self.callingView;
        } else if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPhone){
            _mailComposer.mailComposeDelegate = self.callingViewiPhone;
        }
    }
    return _mailComposer;
}

-(CCDetailViewController *)callingView{
    if (_callingView == nil) {
        CCAppDelegate *appDelegate = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
        UISplitViewController *svc = (UISplitViewController *)appDelegate.window.rootViewController;
        UINavigationController *nc = [svc.viewControllers objectAtIndex:0];
        CCMasterViewController *mc = (CCMasterViewController *)nc.topViewController;
        _callingView = mc.detailViewController;
    }
    
    return _callingView;
}

-(CCiPhoneMasterViewController *)callingViewiPhone{
    if (_callingViewiPhone == nil) {
        CCAppDelegate *appDelegate = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
        UINavigationController *navigationController = (UINavigationController *)appDelegate.window.rootViewController;
        _callingViewiPhone = (CCiPhoneMasterViewController *)navigationController.topViewController;
    }
    return _callingViewiPhone;
}

-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}
@end
