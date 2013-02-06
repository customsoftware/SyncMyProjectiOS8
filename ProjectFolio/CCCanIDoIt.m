//
//  CCCanIDoIt.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/8/12.
//
//

#import "CCCanIDoIt.h"
#define PROJECT_COMPLETE [[NSNumber alloc] initWithInt:1]
#define DAYS (24*60*60)

@implementation CCCanIDoIt{
    NSFetchRequest *fetchRequest;
    NSManagedObjectContext *context;
    NSFetchedResultsController *controller;
}


-(int)workDay{
    return 8;
}

-(float)getWorkDays:(float)totalDays{
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:(NSWeekdayCalendarUnit) fromDate:today];    
    float remainingDays = totalDays;
    if (components.weekday == 7 ) {
        remainingDays = remainingDays + 2;
    } else if (components.weekday == 1){
        remainingDays = remainingDays + 1;
    }
    
    float workingDays;
    float remainingWeeks = remainingDays/7;
    int integerWeek = floor(remainingWeeks);
    if (integerWeek > 0) {
        workingDays = integerWeek * 5;
        workingDays = (totalDays - ( integerWeek * 7 )) + workingDays;
    } else {
        workingDays = totalDays;
    }
    return workingDays;
}

-(float)getRemainingHoursForProject:(Project *)project{
    float hoursUsed = [project.hourBudget floatValue];
    NSArray *events = [project.projectWork allObjects];
    for (WorkTime *event in events) {
        hoursUsed = hoursUsed - [event.end timeIntervalSinceDate:event.start]/3600;
    }
    return hoursUsed;
}

#pragma mark - Work functions
-(NSString *)analyzeProject:(Project *)project{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
    [numberFormatter setMinimumFractionDigits:2];
    [numberFormatter setMinimumIntegerDigits:1];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *retValue = nil;
    if (project.dateFinish == nil) {
        retValue = @"You haven't set a finish date. There's no way to tell";
        
    } else if( project.complete == PROJECT_COMPLETE ){
        retValue = @"The project is completed. No worries man!";
        
    } else if( [project.hourBudget integerValue] == 0 ){
        retValue = @"There are no hours projected. Can't tell until 'Hour Budget' is set.";
        
    } else if( [project.dateFinish timeIntervalSinceNow] < 0 ){
        retValue = @"The project is overdue. You need to adjust the finish date";
        
    } else {
        // Need to get the burn rate to finish. If it's greater than  [self workDay] we can't finish
        float availableDays = [self getWorkDays:[project.dateFinish timeIntervalSinceNow]/DAYS];
        //NSLog(@"Available days %f", availableDays);
        float hourBudget = [self getRemainingHoursForProject:project];
        
        // Compute competing hours from other projects -- This is Sum(project.hourBudget) - Sum(project.workProject.intervals)
        // Project is not complete
        // Project has hourly budget and remaining hours
        NSError *requestError = nil;
        if (![self.controller performFetch:&requestError]) {
            // NSLog(@"Fetch failed");
        }
        
        // Include just projects that have a start date before the finish date of this project
        NSArray *projectList = self.controller.fetchedObjects;
        NSDate *comparisonDate;
        NSMutableArray *averageTimes = [[NSMutableArray alloc]init];
        
        //NSLog(@"How many project: %d", [projectList count]);
        for (Project *competingProject in projectList) {
            if ([competingProject.dateStart laterDate:project.dateFinish] && [competingProject.hourBudget floatValue] > 0.0f && ![competingProject.projectName isEqualToString:project.projectName]) {
                float competingProjectHours = [self getRemainingHoursForProject:competingProject];
                if (competingProjectHours > 0) {
                    
                    // NSLog(@"We need to consider hours for %@", competingProject.projectName);
                    float competingProjectWorkDays = [self getWorkDays:[competingProject.dateFinish timeIntervalSinceNow]/DAYS];
                    if (competingProjectWorkDays > 0) {
                        //NSLog(@"Project: %@ Remaining hours %f Available Days %f", competingProject.projectName, competingProjectHours, competingProjectWorkDays);
                        
                        // Compute average burn rate for these projects
                        float averageBurnRate = competingProjectHours/competingProjectWorkDays;
                        
                        // Get overlapping days
                        if ([competingProject.dateFinish timeIntervalSinceDate:project.dateFinish] > 0) {
                            comparisonDate = [competingProject.dateFinish laterDate:project.dateFinish];
                        } else {
                            comparisonDate = [competingProject.dateFinish earlierDate:project.dateFinish];
                        }
                        //NSLog(@"Project: %@ Effective End date: %@", competingProject.projectName, [comparisonDate description]);
                        // Multiply average burn rate by number of overlapping days
                        float overlappingTime = [self getWorkDays:[comparisonDate timeIntervalSinceDate:[NSDate date]]/DAYS];
                        //NSLog(@"Overlapping time: %f Average burn rate: %f For Project %@", overlappingTime, averageBurnRate, competingProject.projectName);
                        float burnTime = averageBurnRate * overlappingTime;
                        [averageTimes addObject:[NSNumber numberWithFloat:burnTime]];
                    } else {
                        // If the project is late, don't average the time, just add the hours to what you have to do to finish this project
                        hourBudget = hourBudget + competingProjectHours;
                    }
                }
            }
        }
        
        float totalBurn;
        // Sum up these values and divide by number of remaining days
        for (NSNumber *numer in averageTimes) {
            totalBurn = totalBurn + [numer floatValue];
        }
        //NSLog(@"Total of average daily burns: %f", totalBurn);
        totalBurn = totalBurn/availableDays;
        
        // Add this to the dailyBurn
        
        // This does the analysis
        float dailyBurn = (hourBudget/availableDays) + totalBurn;
        //NSLog(@"Daily burn rate to finish main project: %f", dailyBurn);
        //NSLog(@"Remaining: %f hours", hourBudget);
        
        // We decide here based upon the analysis
        if (dailyBurn >= 24) {
            retValue = [[NSString alloc]initWithFormat:@"You can't finish the project by: %@. Push out the delivery date.", [dateFormatter stringFromDate:project.dateFinish]];
        } else if (dailyBurn > [self workDay] && dailyBurn < 24) {
            retValue = [[NSString alloc]initWithFormat:@"You can finish the project by: %@ only by working long days.\n\rYou need to work: %@ per day every day to finish on time.", [dateFormatter stringFromDate:project.dateFinish], [numberFormatter stringFromNumber:[NSNumber numberWithFloat:round(dailyBurn*100)/100]]];
        } else {
            retValue = [[NSString alloc]initWithFormat:@"You can do it by: %@", [dateFormatter stringFromDate:project.dateFinish]];
        }
    }
    
    return retValue;
}

#pragma mark - API
-(CCCanIDoIt *)initWithProject:(Project *)project{
    CCCanIDoIt * retvalue = [super init];
    // Do some logic here with the project
    NSString * projectName = project.projectName;
    
    NSString * analysisResult = [self analyzeProject:project];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:projectName
                          message:analysisResult
                          delegate:self
                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    return retvalue;
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (fetchRequest == nil) {
        fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.context];
        [fetchRequest setEntity:entity];
        NSSortDescriptor *nullDescriptor = [[NSSortDescriptor alloc]initWithKey:@"projectName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:nullDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"complete == 0 AND active == 1"];
        [fetchRequest setPredicate:predicate];
    }
    return fetchRequest;
}

-(NSManagedObjectContext *)context{
    if (context == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        context = application.managedObjectContext;
        
    }
    return context;
}

-(NSFetchedResultsController *)controller{
    if (controller == nil) {
        controller = [[NSFetchedResultsController alloc]
                      initWithFetchRequest:self.fetchRequest managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
    }
    return controller;
}
@end
