//
//  Task+CategoryTask.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import "Task+CategoryTask.h"

@implementation Task (CategoryTask)

-(void)setLevelWith:(NSNumber *)newLevel{
    self.level = newLevel;
    if (self.subTasks != nil && [self.subTasks count] > 0) {
        int nextLevel = [newLevel intValue];
        nextLevel++;
        NSNumber *nextLevelNumber = [NSNumber numberWithInt:nextLevel];
        for (Task *subTask in self.subTasks) {
            [subTask setLevelWith:nextLevelNumber];
        }
    }
}

-(void)setSubTaskVisible:(NSNumber *)visible{
    if ([visible boolValue] == NO) {
        for (Task *subTask in self.subTasks) {
            [subTask setSubTaskVisible:visible];
        }
    }
    self.visible = visible;
}

-(NSNumber *)isOverDue{
    BOOL isTaskOverDue = NO;
    
    NSDate *today = [NSDate date];
    if (self.dueDate != nil) {
        if ([self.dueDate compare:today] == NSOrderedAscending){
            isTaskOverDue = YES;
            // NSLog(@"This is overdue");
        }
    }
    return  [NSNumber numberWithBool:isTaskOverDue];
}


-(void)addSubTasksObject:(Task *)value{
    if (self.subTasks == nil) {
        self.subTasks = [NSSet setWithObject:value];
    } else {
        NSMutableSet *transferSet = [[NSMutableSet alloc] initWithSet:self.subTasks];
        [transferSet addObject:value];
        self.subTasks = [NSSet setWithSet:transferSet];
    }
}

-(void)addSubTasks:(NSSet *)value{
    self.subTasks = nil;
    self.subTasks = value;
}

- (void)removeSubTasksObject:(Task *)value{
    NSMutableSet *transferSet = [[NSMutableSet alloc] initWithSet:self.subTasks];
    [transferSet removeObject:value];
    self.subTasks = [NSSet setWithSet:transferSet];
}

-(NSMutableArray *)removeSubTasksFromArray:(NSMutableArray *)taskList basedUponTask:(Task *)task{
    for (Task *subTask in task.subTasks) {
        taskList = [self removeSubTasksFromArray:taskList basedUponTask:subTask];
        [taskList removeObject:subTask];
    }
    return taskList;
}

-(BOOL)isExpanded{
    BOOL retvalue;
    if ( self.subTasks == nil || [self.subTasks count] == 0) {
        retvalue = NO;
    } else {
        Task * subTask = [[self.subTasks allObjects] objectAtIndex:0];
        if ([subTask.visible boolValue] == YES) {
            retvalue = YES;
        } else {
            retvalue = NO;
        }
    }
    return retvalue;
}

-(NSNumber *)setNewDisplayOrderWith:(NSNumber *)newOrder{
    // Order these by due date
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:YES];
    NSArray *sort = [NSArray arrayWithObject:dateDescriptor];
    NSArray *sortedArray = [[self.subTasks allObjects] sortedArrayUsingDescriptors:sort];
    NSSet *newSet = [[NSSet alloc] initWithArray:sortedArray];
    self.subTasks = newSet;
    
    for (Task *subTask in self.subTasks) {
        double n = [newOrder doubleValue];
        n = n + .1;
        newOrder = [NSNumber numberWithDouble:n];
        subTask.displayOrder = newOrder;
        // NSLog(@"%f", n);
        newOrder = [subTask setNewDisplayOrderWith:newOrder];
    }
    return newOrder;
}

-(void)updateSubTaskCompletion:(NSNumber *)complete{
    for (Task *task in self.subTasks) {
        task.completed = complete;
        [task updateSubTaskCompletion:complete];
    }
}

- (NSString *)getTaskNotesWithString:(NSString *)messageString{
    NSString *retValue = nil;
    if (self.notes == nil) {
        retValue = [[NSString alloc] initWithFormat:@"%@<p><b>%@: </b>There are no notes.", messageString, self.title];
    } else {
        retValue = [[NSString alloc] initWithFormat:@"%@<p><b>%@</b><p>Notes: %@", messageString, self.title, self.notes];
    }
    for (Task *subTask in self.subTasks) {
        retValue = [subTask getTaskNotesWithString:retValue];
    }
    return retValue;
}

-(NSDate *)latestDate{
    NSDate *returnDate = nil;
    if (self.dueDate != nil && [self.completed boolValue] == NO) {
        returnDate = self.dueDate;
    }
    
    for (Task * subTask in self.subTasks) {
        if (subTask.dueDate != nil && [subTask.completed boolValue] == NO) {
            if (returnDate == nil) {
                returnDate = subTask.dueDate;
            } else {
                returnDate = [returnDate laterDate:[subTask latestDate]];
            }
        }
        
    }
    
    return returnDate;
}

-(NSDate *)earliestDate{
    NSDate *returnDate = nil;
    if (self.dueDate != nil && [self.completed boolValue] == NO) {
        returnDate = self.dueDate;
    }
    
    for (Task * subTask in self.subTasks) {
        if (subTask.dueDate != nil && [subTask.completed boolValue] == NO) {
            if (returnDate == nil) {
                returnDate = subTask.dueDate;
            } else {
                returnDate = [returnDate earlierDate:[subTask latestDate]];
            }
        }
        
    }
    
    return returnDate;
}

- (NSNumber *)virtualComplete{
    NSNumber *retValue = nil;
    if (self.superTask == nil) {
        retValue = self.completed;
    } else {
        if ([self.superTask.completed boolValue] == YES && [self.completed boolValue] == NO) {
            retValue = self.superTask.completed;
        } else {
            retValue = self.completed;
        }
    }
    return retValue;
}

@end
