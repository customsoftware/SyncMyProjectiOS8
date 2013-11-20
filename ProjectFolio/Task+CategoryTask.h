//
//  Task+CategoryTask.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import "Task.h"

@interface Task (CategoryTask)

// Custom procedures
- (void)setLevelWith:(NSNumber *)newLevel;
- (void)setSubTaskVisible:(NSNumber *)visible;
- (NSMutableArray *)removeSubTasksFromArray:(NSMutableArray *)taskList basedUponTask:(Task *)task;
- (BOOL)isExpanded;
- (NSNumber *)setNewDisplayOrderWith:(NSNumber *)newOrder;
- (void)updateSubTaskCompletion:(NSNumber *)complete;
- (NSString *)getTaskNotesWithString:(NSString *)messageString;
- (NSDate *)latestDate;
- (NSDate *)earliestDate;
- (NSNumber *)virtualComplete;

@end
