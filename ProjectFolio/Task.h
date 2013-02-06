//
//  Task.h
//  ProjectFolio
//
//  Created by Ken Cluff on 12/4/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Priority, Project, Task;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * assignedFirst;
@property (nonatomic, retain) NSString * assignedLast;
@property (nonatomic, retain) NSString * assignedTo;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSNumber * completionRate;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * isOverDue;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * taskID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSSet *subTasks;
@property (nonatomic, retain) Task *superTask;
@property (nonatomic, retain) Priority *taskPriority;
@property (nonatomic, retain) Project *taskProject;
@end

@interface Task (CoreDataGeneratedAccessors)

- (void)addSubTasksObject:(Task *)value;
- (void)removeSubTasksObject:(Task *)value;
- (void)addSubTasks:(NSSet *)values;
- (void)removeSubTasks:(NSSet *)values;
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
