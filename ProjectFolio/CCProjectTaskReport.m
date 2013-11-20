//
//  CCProjectTaskReport.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/19/13.
//
//

#import "CCProjectTaskReport.h"
#import "Project.h"
#import "Task.h"
#import "WorkTime+CategoryWorkTimeQuery.h"

#define kPredicateString        @"(workProject.complete = %@) AND ( billed = %@)"
#define kPredicateArray         @[@"0",@"1"]
#define kGroupProjectString     @"workProject.projectUUID"
#define kGroupTaskString        @"workTask.taskUUID"
#define kSortDateString         @"MIN( start )"
#define kEntity                 @"WorkTime"

@implementation CCProjectTaskReport

+ (NSArray *) getReportGroupedByProjectTaskDateForDateRange:(kRangeModes) rangeMode fromDate:(NSDate *)startDate {
    // The query we want to replace:
    /*
     SELECT MIN( w.start ) as startDate, p.projectName, @"        " as title, SUM( w.end - w.start ) as ElapseTime
        FROM Project p
            INNER JOIN WorkTime w ON p.projectID = w.projectID
       WHERE p.completed = 0
         AND p.active = 1
     GROUP BY p.projectName
     ORDER BY p.projectName, title, startDate
     UNION ALL
     SELECT MIN( w.start ) as startDate, p.projectName, t.title as title, SUM( w.end - w.start ) as ElapseTime
        FROM Project p
            INNER JOIN WorkTime w ON p.projectID = w.projectID
            INNER JOIN Task t ON t.projectID = t.projectID
       WHERE p.completed = 0
         AND p.active = 1
    GROUP BY p.projectName
    ORDER BY p.projectName, title, startDate
     
    */
    // Set the field array
    // Set the where clause
    NSPredicate *predicate = [NSPredicate predicateWithFormat:kPredicateString argumentArray:kPredicateArray];
    // Set the order by clause
    NSSortDescriptor *sortProject = [[NSSortDescriptor alloc] initWithKey:kGroupProjectString ascending:YES];
    NSSortDescriptor *sortTask = [[NSSortDescriptor alloc] initWithKey:kGroupTaskString ascending:YES];
    NSSortDescriptor *sortDate = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:YES];
    NSArray *sortArray = @[sortProject,sortTask,sortDate];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kEntity];
    [request setSortDescriptors:sortArray];
    [request setPredicate:predicate];
    [request setResultType:NSDictionaryResultType];
    
    NSFetchedResultsController *eventFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                        managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                          sectionNameKeyPath:nil
                                                                   cacheName:nil];
    [eventFRC performFetch:nil];
    NSArray *taskArray = eventFRC.fetchedObjects;
    return  taskArray;
}

@end
