//
//  CCMostRecentTasks.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/18/13.
//
//

#import "CCMostRecentTasks.h"
#import "WorkTime.h"
#import "Task.h"
#define kSortField      @"end"
#define kEntityName     @"WorkTime"
#define kGroupField     @"workTask.title"
#define kGroupEntity    @"workProject.projectName"

@implementation CCMostRecentTasks

+ (NSArray *)mostRecentTasks:(NSUInteger)numberToReturn {
    // We need a fetch request to get the data
    // We need to order the results
    // We need an aggregation
    /* In SQL this is what we want: 
        SELECT TOP numberToReturn workTask, MAX( end ) as lastEdited
            FROM WorkTime
           WHERE end is not null
             AND workProject.complete = 0
        GROUP BY workTask
        ORDER BY MAX( end ) DESC
     
     //create the NSExpression to tell our NSExpressionDescription which calculation we are performing.
     NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyExpression]];

     
    */
    NSSortDescriptor *resultSort = [[NSSortDescriptor alloc] initWithKey:kSortField ascending:NO];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"(end != NULL) AND ( workProject.complete = 0) AND ( workTask.completed = 0 )"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:kEntityName];
    [request setSortDescriptors:@[resultSort]];
    [request setPredicate:filter];
    [request setPropertiesToFetch:@[kGroupField, kGroupEntity]];
    [request setPropertiesToGroupBy:@[kGroupField, kGroupEntity]];
    [request setResultType:NSDictionaryResultType];
    NSManagedObjectContext *context = [[CoreData sharedModel:nil] managedObjectContext];
    
    NSError *error = nil;
    NSArray *taskArray = [context executeFetchRequest:request error:&error];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:numberToReturn];
    
    int arrayLimit = MIN(numberToReturn, taskArray.count);
    
    for (int x = 0; x < arrayLimit; x++) {
        NSDictionary *dictionary = taskArray[x];
        [results addObject:dictionary];
    }
    
    return results;
}

@end
