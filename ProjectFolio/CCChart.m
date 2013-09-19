//
//  CCChart.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/28/12.
//
//

#import "CCChart.h"
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]
#define DAYS (60*60*24)
#define kActiveProject @"activeProject"
#define baseLine 15
#define barDrop 20
#define barIndent 15
#define barThickness 7
#define runningOnIPad    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

@interface CCChart ()

@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSString *projectName;
@property (strong, nonatomic) NSString *projectUUID;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) NSFetchedResultsController *taskFRC;
@property (nonatomic) int iOS7Extra;

@end

@implementation CCChart

#pragma  mark - Init
-(CCChart *)initWithProject:(Project *)controllingProject andFrame:(CGRect)frame;{
    self = [super init];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark - drawing functions
-(void)drawBoundWithRect:(CGRect)rect andDuration:(float)length inContext:(CGContextRef) context{
    UIColor *normalBoxColor = [UIColor blackColor];
    CGMutablePathRef path = CGPathCreateMutable();
    rect.origin.y = rect.origin.y + 20;
    if (length < barIndent) {
        length = barIndent;
    }
    CGContextSetLineWidth(context, 1.5f);
    [normalBoxColor setFill];
    [normalBoxColor setStroke];
    
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rect.origin.x + length, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rect.origin.x + length, rect.origin.y + barDrop);
    CGPathAddLineToPoint(path, NULL, rect.origin.x + length - barIndent, rect.origin.y + barThickness);
    CGPathAddLineToPoint(path, NULL, rect.origin.x + barIndent, rect.origin.y + barThickness);
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y + barDrop);
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGContextAddPath(context, path);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGPathRelease(path);
}

- (void)drawLabelforTask:(Task *)sourceTask withRect:(CGRect)rect{
    UIFont *labelBoldFont = [UIFont boldSystemFontOfSize:17];
    UIFont *labelNormalFont = [UIFont systemFontOfSize:16];
    UIColor *normalColor = [UIColor blackColor];
    UIColor *completeColor = [UIColor colorWithHue:0.333 saturation:.8 brightness:.539 alpha:1];
    UIColor *lateColor  = [UIColor redColor];
    
    NSString *label = sourceTask.title;
    if ([sourceTask.virtualComplete boolValue] == YES) {
        [completeColor setFill];
        // rect.origin.x = baseLine;
    } else if ( sourceTask.dueDate != nil && [sourceTask.dueDate timeIntervalSinceDate:[NSDate date]] < 0 ) {
        [lateColor setFill];
    } else {
        [normalColor setFill];
    }
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    attributes[NSFontAttributeName] = labelBoldFont;
    
    if ([sourceTask.subTasks count] > 0) {
        attributes[NSFontAttributeName] = labelBoldFont;
    } else {
        attributes[NSFontAttributeName] = labelNormalFont;
    }
    [label drawInRect:rect withAttributes:attributes];
}

#pragma  mark - API
-(void)drawRect:(CGRect)rect{
    self.projectUUID = [[NSString alloc] initWithFormat:@"%@",[self.defaults objectForKey:kActiveProject]];
    if (!runningOnIPad) {
        self.iOS7Extra = 10;
    } else { self.iOS7Extra = 0; }
    
    if (self.projectUUID == nil) {
        // NSLog(@"Bailing: No Project name");
    } else {
        NSError *fetchError;
        rect.size.width = rect.size.width - 21;
    
        [self.fetchedProjectsController performFetch:&fetchError];
        
        if (self.fetchedProjectsController.fetchedObjects.count > 0) {
            self.controllingProject = [[self.fetchedProjectsController fetchedObjects] objectAtIndex:0];
            [self.taskFRC performFetch:&fetchError];
            
            CGFloat height = rect.size.height;
            CGFloat width = rect.size.width;
            
            float pointsPerDay = [self getPointsPerDay:width];
            NSDate *baseDate = self.controllingProject.dateStart;
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGFloat y = 44 + self.iOS7Extra;
            CGFloat x = (([[NSDate date] timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay) + baseLine;
            CGFloat barWidth = 1;
            CGRect barRect = CGRectMake(x, y, barWidth, height );
            //NSLog(@"Day dimensions - x:%f y:%f width:%f height:%f", barRect.origin.x, barRect.origin.y, barRect.size.width, barRect.size.height);
            
            // Set Start - a dark grey line
            [[UIColor darkGrayColor] setStroke];
            CGContextSetLineWidth(context, 1.5f);
            CGContextMoveToPoint(context, baseLine - 1, barRect.origin.y);
            CGContextAddLineToPoint(context, baseLine - 1, barRect.size.height);
            CGContextStrokePath(context);
            
            // Set Today - a light grey line
            [[UIColor lightGrayColor] setStroke];
            CGContextSetLineWidth(context, 1.0f);
            CGContextMoveToPoint(context, barRect.origin.x, barRect.origin.y);
            CGContextAddLineToPoint(context, barRect.origin.x, barRect.size.height);
            CGContextStrokePath(context);
            
            // Set End Date - a  doublered line
            if (self.controllingProject.dateFinish != nil) {
                [[UIColor redColor] setStroke];
                CGContextMoveToPoint(context, (18 + ([self.controllingProject.dateFinish timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay), barRect.origin.y);
                CGContextAddLineToPoint(context, (18 + ([self.controllingProject.dateFinish timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay), barRect.size.height);
                CGContextStrokePath(context);
                CGContextMoveToPoint(context, (21 + ([self.controllingProject.dateFinish timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay), barRect.origin.y);
                CGContextAddLineToPoint(context, (21 + ([self.controllingProject.dateFinish timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay), barRect.size.height);
                CGContextStrokePath(context);
                
            }

            
            // Initialie the pointers
            y = 54 + self.iOS7Extra;
            x = baseLine;
            float x_delta;
            CGContextSetShadowWithColor(context, CGSizeMake(5.0f, 5.0f), 5.0f, [[UIColor lightGrayColor] CGColor]);
            
            // [self testDrawBoundWithRect:rect inContext:context];
            
            for (Task *taskEntry in self.taskFRC.fetchedObjects) {
                // We don't change Y since this moves down the chart
                y = y + 25;
                
                // We do change x depending on what's happening
                rect = CGRectMake(x, y - 25.0f, 540.0f, 25.0);
                // List the name of the task
                [self drawLabelforTask:taskEntry withRect:rect];
                if ([taskEntry.subTasks count] > 0){
                    if (taskEntry.latestDate == nil) {
                        x_delta = ([self.controllingProject.dateFinish timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay;
                    } else {
                        x_delta = ([taskEntry.latestDate timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay;
                    }
                    if (isnan(x_delta)) {
                        x_delta = 0;
                    }
                    [self drawBoundWithRect:rect andDuration:(baseLine + x_delta - x) inContext:context];
                    y = y + 10 + self.iOS7Extra;
                } else if ( [taskEntry.duration floatValue] > 0 ) {
                    // NSLog(@"Task: %@ has a duration of %f hours", taskEntry.title, [taskEntry.duration doubleValue]);
                    x_delta = ([taskEntry.duration floatValue]/8 ) *pointsPerDay;
                    if (isnan(x_delta)) {
                        x_delta = 0;
                    }
                    [[UIColor darkGrayColor] setStroke];
                    CGContextSetLineWidth(context, 3.5f);
                    CGContextMoveToPoint(context, x, y);
                    CGContextAddLineToPoint(context, x + x_delta, y);
                    CGContextStrokePath(context);
                } else {
                    x_delta =  (([taskEntry.dueDate timeIntervalSinceDate:baseDate]/DAYS)*pointsPerDay);
                    if (isnan(x_delta)) {
                        x_delta = 0;
                    }
                }
                
                // Move the next set of tasks over to the left
                if ((taskEntry.duration != nil || taskEntry.dueDate != nil )&& [taskEntry.subTasks count] == 0 && [taskEntry.virtualComplete boolValue] == NO) {
                    x = x + x_delta;
                }
            }
            
            
            UIGraphicsEndImageContext();
        }
    }
}

-(void)refreshDrawing{
    CGRect rect = [self bounds];
    self.controllingProject = [self.taskChartDelegate getControllingProject];
    [self drawRect:rect];
}

#pragma  mark - Support Functions
-(float)getPointsPerDay:(CGFloat)width{
    NSTimeInterval time = [[self getLatestEnd] timeIntervalSinceDate:[self getEarliestStart]];
    time = time/DAYS;
    float retValue;
    if (time > 0) {
        retValue = (width/time)* 0.75;
    } else {
        retValue = 1;
    }
    //NSLog(@"Width: %f Number of days: %f Points per day: %f", width, time, retValue);
    return retValue;
}

-(NSDate *)getEarliestStart{
    // NSLog(@"Start Date: %@", [self.controllingProject.dateStart description]);
    return self.controllingProject.dateStart;
}

-(NSDate *)getLatestEnd{
    NSDate *returnValue = nil;
    
    if (self.controllingProject.dateFinish != nil) {
        returnValue = self.controllingProject.dateFinish;
    } else {
        // Find the latest task due date
        for (Task *task in self.controllingProject.projectTask) {
            returnValue = [returnValue laterDate:task.dueDate];
        }
    }
    if (returnValue == nil) {
        returnValue = [NSDate date];
    }
    
    returnValue = [returnValue laterDate:[NSDate date]];
    
    // NSLog(@"Latest finish: %@", [returnValue description]);
    return returnValue;
}

#pragma mark - Lazy Getter
-(NSUserDefaults *)defaults{
    if (_defaults == nil) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
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
        NSPredicate *completedPredicate = [NSPredicate predicateWithFormat:@"projectUUID = %@", self.projectUUID];
        [fetchRequest setPredicate:completedPredicate];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                                 initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                                 sectionNameKeyPath:nil cacheName:nil];
        
        _fetchedProjectsController = aFetchedResultsController;
    }
    return _fetchedProjectsController;
}

-(NSFetchedResultsController *)taskFRC{
    if (_taskFRC == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task"
                                                  inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        [fetchRequest setEntity:entity];
        //NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completed" ascending:YES];
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        NSPredicate *completedPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectUUID = %@", self.projectUUID];
        [fetchRequest setPredicate:completedPredicate];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                                 initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                                 sectionNameKeyPath:nil cacheName:nil];
        
        _taskFRC = aFetchedResultsController;
    }
    return _taskFRC;
}

@end
