//
//  Task.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Priority, Project, Task, WorkTime;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * assignedFirst;
@property (nonatomic, retain) NSString * assignedLast;
@property (nonatomic, retain) NSString * assignedTo;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSNumber * completionRate;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSDate * dueDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * isOverDue;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * taskID;
@property (nonatomic, retain) NSString * taskUUID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSSet *subTasks;
@property (nonatomic, retain) Task *superTask;
@property (nonatomic, retain) Priority *taskPriority;
@property (nonatomic, retain) Project *taskProject;
@property (nonatomic, retain) NSSet *taskTimer;
@end

@interface Task (CoreDataGeneratedAccessors)

- (void)addSubTasksObject:(Task *)value;
- (void)removeSubTasksObject:(Task *)value;
- (void)addSubTasks:(NSSet *)values;
- (void)removeSubTasks:(NSSet *)values;

- (void)addTaskTimerObject:(WorkTime *)value;
- (void)removeTaskTimerObject:(WorkTime *)value;
- (void)addTaskTimer:(NSSet *)values;
- (void)removeTaskTimer:(NSSet *)values;

@end
