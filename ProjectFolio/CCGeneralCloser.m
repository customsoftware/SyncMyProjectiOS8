//
//  CCGeneralCloser.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/6/12.
//
//

#import "CCGeneralCloser.h"
#define ALL_UNBILLED  0
#define YESTERDAY_UNBILLED 1
#define LAST_WEEK_UNBILLED 3
#define THIS_WEEK_UNBILLED 2

#define TWO_DAY 48*60*60
#define ONE_DAY 24*60*60
#define ONE_WEEK 24*60*60*7

@interface CCGeneralCloser()
@property (strong, nonatomic) NSString *subjectLine;
@property (assign, nonatomic) CCMasterViewController *callingView;
@property (assign, nonatomic) CCiPhoneMasterViewController *callingViewiPhone;
@property (strong, nonatomic) NSMutableArray *projectResults;
@property (strong, nonatomic) NSMutableArray *dailyResults;
@property (strong, nonatomic) NSArray *billableResults;
@property NSInteger mode;

@end

@implementation CCGeneralCloser
@synthesize mailComposer = _mailComposer;
@synthesize subjectLine = _subjectLine;
@synthesize callingView = _callingView;
@synthesize mode = _mode;

#pragma mark - Life Cycle
-(void)viewDidLoad{
    [super viewDidLoad];
    
}

-(void)viewDidUnload{
    [super viewDidUnload];
    self.mailComposer = nil;
    self.subjectLine = nil;
    self.callingView = nil;
    self.projectResults = nil;
    self.dailyResults = nil;
    self.callingViewiPhone = nil;
}

#pragma mark - Init Variations
-(CCGeneralCloser *)initForAll{
    CCGeneralCloser *newCloser = [super init];
    self.mode = ALL_UNBILLED;
    self.subjectLine = @"Close all active projects";
    return newCloser;
}

-(CCGeneralCloser *)initForYesterday{
    CCGeneralCloser *newCloser = [super init];
    self.mode = YESTERDAY_UNBILLED;
    self.subjectLine = @"Close yesterday's projects";
    return newCloser;
}

-(CCGeneralCloser *)initWithLastWeek{
    CCGeneralCloser *newCloser = [super init];
    self.mode = THIS_WEEK_UNBILLED;
    self.subjectLine = @"Close last week's projects";
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *projectDescriptor = [[NSSortDescriptor alloc] initWithKey:@"workProject.projectName" ascending:YES];
    NSSortDescriptor *startDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:projectDescriptor, startDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    NSPredicate *completedPredicate = nil;
    if ([self getStart] != nil){
        completedPredicate = [NSPredicate predicateWithFormat:@"workProject.projectName != nil AND ( billed == nil OR billed == 0) AND start >= %@ AND start <= %@", [self getStart], [self getEnd]];
    } else {
        completedPredicate = [NSPredicate predicateWithFormat:@"workProject.projectName != nil AND ( billed == nil OR billed == 0 ) AND end != nil"];        
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
    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
    if (self.subjectLine == nil) {
        self.subjectLine = @"Whoops";
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:2];
    [numberFormatter setMinimumIntegerDigits:1];
    [numberFormatter setRoundingMode:NSNumberFormatterRoundUp];
    NSMutableString *messageString = [[NSMutableString alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *newProject = nil; //[[NSString alloc] initWithFormat:@"Who me???"];
    NSString *oldProject = nil; //[[NSString alloc] initWithFormat:@"Who me???"];
    NSString *newDate = nil; //[[NSString alloc] initWithFormat:@"Who me???"];
    NSString *oldDate = [[NSString alloc] initWithFormat:@"Who me???"];
    float currentInterval = 0;
    float projectInterval = 0;
    float totalInterval = 0;
        
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
            //NSString *newString = [[NSString alloc]
            //                       initWithFormat:@"Project: %@\tDay: %@\tElapse time:\t%@", newProject, newDate, [numberFormatter stringFromNumber:[NSNumber numberWithFloat:elapseTime]]];
            //[messageString appendString:newString];
            //[messageString appendString:@"\n\r"];
   
            if ([newProject isEqualToString:oldProject]) {
                if ([newDate isEqualToString:oldDate]) {
                    // Update the daily and project counters
                    currentInterval = currentInterval + elapseTime;
                    projectInterval = projectInterval + elapseTime;
                } else {
                    // Write the daily record
                    newString = [[NSString alloc] initWithFormat:@"\t\t\tDay: %@\tElapse time:\t%@",
                                 oldDate,
                                 [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                    [messageString appendString:newString];
                    [messageString appendString:@"\n\r"];
                    
                    // Reset the daily counter
                    currentInterval = elapseTime;
                    // Update the project counter
                    projectInterval = projectInterval + elapseTime;
                }
            } else {
                // Changing Project .. Write the last Day
                if (![oldProject isEqualToString:@"Who me???"]) {
                    if (self.mode != YESTERDAY_UNBILLED) {
                        newString = [[NSString alloc] initWithFormat:@"\t\t\tDay: %@\tElapse time:\t%@",
                                     oldDate,
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                        [messageString appendString:newString];
                        [messageString appendString:@"\n\r"];
                        
                        newString = [[NSString alloc] initWithFormat:@"----------------------------------------\n\r"];
                        [messageString appendString:newString];
                        
                        newString = [[NSString alloc] initWithFormat:@"\tSub-total Elapse time:\t%@",
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:projectInterval]]];
                        [messageString appendString:newString];
                        [messageString appendString:@"\n\r\n\r"];
 
                        newString = [[NSString alloc] initWithFormat:@"Project: %@", newProject];
                        [messageString appendString:newString];
                        [messageString appendString:@"\n\r"];
                    } else {
                        newString = [[NSString alloc] initWithFormat:@"Project: %@\t\tDay: %@\tElapse time:\t%@",
                                     oldProject,
                                     oldDate,
                                     [numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                        [messageString appendString:newString];
                        [messageString appendString:@"\n\r"];
                    }
                    
                } else if ( ![newProject isEqualToString:@"Who me???"]  && self.mode != YESTERDAY_UNBILLED){
                    
                    newString = [[NSString alloc] initWithFormat:@"Project: %@", newProject];
                    [messageString appendString:newString];
                    [messageString appendString:@"\n\r"];
                }
                // Reset the daily and project summaries
                currentInterval = elapseTime;
                projectInterval = elapseTime;
            }
            // Get ready for the next Loop
            totalInterval = totalInterval + elapseTime;
            oldDate = newDate;
            oldProject = newProject;
        }
        

        //event.billed = [NSNumber numberWithInt:1];
    }
    if (currentInterval != 0) {
        if (![oldProject isEqualToString:@"Who me???"]) {            
            if (self.mode != YESTERDAY_UNBILLED) {
                NSString *newString = [[NSString alloc] initWithFormat:@"\t\tDay: %@\tElapse time:\t%@", oldDate,[numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                [messageString appendString:newString];
                [messageString appendString:@"\n\r"];
                
                newString = [[NSString alloc] initWithFormat:@"----------------------------------------\n\r"];
                [messageString appendString:newString];
                
                newString = [[NSString alloc] initWithFormat:@"\tSub-total Elapse time:\t%@",
                             [numberFormatter stringFromNumber:[NSNumber numberWithFloat:projectInterval]]];
                [messageString appendString:newString];
                [messageString appendString:@"\n\r\n\r"];
            } else {
                NSString *newString = [[NSString alloc] initWithFormat:@"Project: %@\tDay: %@\tElapse time:\t%@", oldProject, oldDate,[numberFormatter stringFromNumber:[NSNumber numberWithFloat:currentInterval]]];
                [messageString appendString:newString];
                [messageString appendString:@"\n\r"];
            }

        }
    }
    
    NSString *newString = [[NSString alloc] initWithFormat:@"Total Elapse time: %@", [numberFormatter stringFromNumber:[NSNumber numberWithFloat:totalInterval]]];
    [messageString appendString:newString];
    
    [self.mailComposer setSubject:self.subjectLine];
    [self.mailComposer setMessageBody:messageString isHTML:NO];
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

-(CCMasterViewController *)callingView{
    if (_callingView == nil) {
        CCAppDelegate *appDelegate = (CCAppDelegate *)[UIApplication sharedApplication].delegate;
        UISplitViewController *svc = (UISplitViewController *)appDelegate.window.rootViewController;
        UINavigationController *nc = [svc.viewControllers objectAtIndex:0];
        _callingView = (CCMasterViewController *)nc.topViewController;
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
