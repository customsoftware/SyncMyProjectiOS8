//
//  CCBarObject.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/23/12.
//
//

#import "CCBarObject.h"
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]
#define DAYS (60*60*24)

@implementation CCBarObject

@synthesize projectList = _projectList;
@synthesize barDelegate = _barDelegate;

#pragma mark - View Data
-(NSInteger )getProjectCount{
    NSInteger retvalue = [self.projectList count];
    return retvalue;
}

-(NSDate *)getEarliestStart{
    NSDate *returnValue = [NSDate date];
    for (Project *project in self.projectList) {
        if (project.active) {
            returnValue = [returnValue earlierDate:project.dateStart];
        }
    }
    //NSLog(@"Earliest Start: %@", [returnValue description]);
    return returnValue;
}

-(NSDate *)getLatestEnd{
    NSDate *returnValue = [NSDate date];
    for (Project *project in self.projectList) {
        returnValue = [returnValue laterDate:project.dateFinish];
    }
    //NSLog(@"Latest finish: %@", [returnValue description]);
    return returnValue;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // Add a filter for just active projects to fetch controller
        /*NSLog(@"Project count: %d", [self getProjectCount]);
        NSLog(@"Earliest start: %@", [self getEarliestStart]);
        NSLog(@"Latest finish: %@", [self getLatestEnd]);*/
    }
    return self;
}

-(float)getPointsPerDay:(CGFloat)width{
    NSTimeInterval time = [[self getLatestEnd] timeIntervalSinceDate:[self getEarliestStart]];
    time = time/DAYS;
    float retValue = width/time;
//    NSLog(@"Width: %f Number of days: %f Points per day: %f", width, time, retValue);
    return retValue;
}

-(NSDate *)getBaselineDate{
    NSDate *retValue = [self getEarliestStart];
    
    return retValue;
}

-(BOOL)projectIsOnTime:(Project *)project{
    NSTimeInterval interval = [project.dateFinish timeIntervalSinceNow];
    interval = interval/DAYS;
    NSTimeInterval earlyInterval = [project.dateStart timeIntervalSinceNow];
    BOOL retValue = (interval > 0) ? YES:NO;
    
    if (earlyInterval > 0) {
        retValue = NO;
    }
    //NSLog(@"Interval for onTime: %f", interval );
    return retValue;
}


-(BOOL)projectIsLate:(Project *)project{
    NSTimeInterval interval = [project.dateFinish timeIntervalSinceNow];
    interval = interval/DAYS;
    //NSLog(@"Interval for isLate: %f", interval );
    BOOL retValue = (interval < 0) ? YES:NO;
    return retValue;
}


-(BOOL)projectIsWaiting:(Project *)project{
    NSTimeInterval interval = [project.dateStart timeIntervalSinceNow];
    interval = interval/DAYS;
    //NSLog(@"Interval for isWaiting: %f", interval );
    BOOL retValue = (interval > 0) ? YES:NO;
    return retValue;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSError *fetchError;
    [self.fetchedProjectsController performFetch:&fetchError];
    self.projectList = [self.fetchedProjectsController fetchedObjects];
    
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    float pointsPerDay = [self getPointsPerDay:width];
    NSDate *baseDate = [self getBaselineDate];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat barHeight = 4;
    // Draw the vertical score for today
    [[UIColor redColor] setFill];
    CGFloat y = 0;
    CGFloat x = (([[NSDate date] timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay) +2;
    CGFloat barWidth = 1;
    CGRect barRect = CGRectMake(x, y, barWidth, height );
    CGContextAddRect(context, barRect);
    CGContextDrawPath(context, kCGPathFill);
    CGContextSetShadowWithColor(context, CGSizeMake(5.0f, 5.0f), 8.0f, [[UIColor lightGrayColor] CGColor]);
    [[UIColor blackColor] setStroke];
    CGContextSetLineWidth(context, 0.25f);
    
    // Repeat for each set of projects ( on time, not started, late, captions and line for today
    // Projects that are on time
    [[UIColor greenColor] setFill];
    for (Project *project in self.projectList) {
        if ([self projectIsOnTime:project]){
            CGFloat y = ([self.projectList indexOfObject:project] +1 )* (barHeight + 30);
	        CGFloat x = (([project.dateStart timeIntervalSinceDate:baseDate]/DAYS) *pointsPerDay ) +2;
	        CGFloat barWidth = ([project.dateFinish timeIntervalSinceDate:project.dateStart]/DAYS)*pointsPerDay;
	        CGRect barRect = CGRectMake(x, y, barWidth, barHeight );
            // NSLog(@"On Time Project: %@ x-pos %f y-pos %f Width %f Height %f", project.projectName, x, y, barWidth, barHeight);
	        CGContextAddRect(context, barRect);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    // Late Projects
    [[UIColor orangeColor] setFill];
    for (Project *project in self.projectList) {
        if ([self projectIsLate:project]){
	        CGFloat y = ([self.projectList indexOfObject:project] +1 )* (barHeight + 30);
	        CGFloat x = (([project.dateStart timeIntervalSinceDate:baseDate]/DAYS) *pointsPerDay ) +2;
	        CGFloat barWidth = ([project.dateFinish timeIntervalSinceDate:project.dateStart]/DAYS)*pointsPerDay;
	        CGRect barRect = CGRectMake(x, y, barWidth, barHeight );
            // NSLog(@"Late Project: %@ x-pos %f y-pos %f Width %f Height %f", project.projectName, x, y, barWidth, barHeight);
	        CGContextAddRect(context, barRect);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    // Projects not started
    [[UIColor grayColor] setFill];
    for (Project *project in self.projectList) {
        if ([self projectIsWaiting:project]){
	        CGFloat y = ([self.projectList indexOfObject:project] +1 )* (barHeight + 30);
	        CGFloat x = (([project.dateStart timeIntervalSinceDate:baseDate]/DAYS) *pointsPerDay ) +2;
	        CGFloat barWidth = ([project.dateFinish timeIntervalSinceDate:project.dateStart]/DAYS)* pointsPerDay;
	        CGRect barRect = CGRectMake(x, y, barWidth, barHeight );
	        // NSLog(@"Early Project: %@ x-pos %f y-pos %f Width %f Height %f", project.projectName, x, y, barWidth, barHeight);
	        CGContextAddRect(context, barRect);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    
    //Draw the text
    [[UIColor blackColor] setFill];
    for (int i = 0; i < [self.projectList count]; i++)
    {
        Project *project = [self.projectList objectAtIndex:i];
        CGFloat y = ([self.projectList indexOfObject:project] +1 )* (barHeight + 30);
        CGFloat x = (([project.dateStart timeIntervalSinceDate:baseDate]/DAYS) *pointsPerDay ) +2;
        NSString *label = project.projectName;
        UIFont *helveticaBold = [UIFont boldSystemFontOfSize:18];
        CGContextSetShadowWithColor(context, CGSizeMake(5.0f, 5.0f), 5.0f, [[UIColor lightGrayColor] CGColor]);
        CGRect textRect = CGRectMake(x, y - 25.0f, 250.0f, 25.0);
        // NSLog(@"Project Label: %@ x-pos %f y-pos %f", project.projectName, x, y);
        [label drawInRect:textRect withFont:helveticaBold];
    }
    
}


-(NSFetchedResultsController *)fetchedProjectsController{
    if (_fetchedProjectsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                  inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        [fetchRequest setEntity:entity];
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateFinish" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        NSPredicate *completedPredicate = [NSPredicate predicateWithFormat:@"active == 1 AND dateFinish != nil"];
        [fetchRequest setPredicate:completedPredicate];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                                 initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                                 sectionNameKeyPath:nil cacheName:@"activeProjectList"];
        
        _fetchedProjectsController = aFetchedResultsController;
    }
    return _fetchedProjectsController;
}

@end