//
//  Project.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Calendar, Deliverables, Priority, Task, WorkTime;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * assignedTo;
@property (nonatomic, retain) NSString * assignedToFirst;
@property (nonatomic, retain) NSString * assignedToLast;
@property (nonatomic, retain) NSNumber * billable;
@property (nonatomic, retain) NSNumber * billed;
@property (nonatomic, retain) NSNumber * complete;
@property (nonatomic, retain) NSDecimalNumber * costBudget;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateFinish;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSDate * dateStart;
@property (nonatomic, retain) NSString * dueTo;
@property (nonatomic, retain) NSString * dueToFirst;
@property (nonatomic, retain) NSString * dueToLast;
@property (nonatomic, retain) NSNumber * hourBudget;
@property (nonatomic, retain) NSNumber * hourlyRate;
@property (nonatomic, retain) NSNumber * isOverDue;
@property (nonatomic, retain) NSString * projectAddressGroup;
@property (nonatomic, retain) NSString * projectCalendarName;
@property (nonatomic, retain) NSString * projectName;
@property (nonatomic, retain) NSString * projectNotes;
@property (nonatomic, retain) NSString * projectUUID;
@property (nonatomic, retain) NSNumber * systemRecord;
@property (nonatomic, retain) NSSet *projectCalendar;
@property (nonatomic, retain) NSSet *projectExpense;
@property (nonatomic, retain) Priority *projectPriority;
@property (nonatomic, retain) NSSet *projectTask;
@property (nonatomic, retain) NSSet *projectWork;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)addProjectCalendarObject:(Calendar *)value;
- (void)removeProjectCalendarObject:(Calendar *)value;
- (void)addProjectCalendar:(NSSet *)values;
- (void)removeProjectCalendar:(NSSet *)values;

- (void)addProjectExpenseObject:(Deliverables *)value;
- (void)removeProjectExpenseObject:(Deliverables *)value;
- (void)addProjectExpense:(NSSet *)values;
- (void)removeProjectExpense:(NSSet *)values;

- (void)addProjectTaskObject:(Task *)value;
- (void)removeProjectTaskObject:(Task *)value;
- (void)addProjectTask:(NSSet *)values;
- (void)removeProjectTask:(NSSet *)values;

- (void)addProjectWorkObject:(WorkTime *)value;
- (void)removeProjectWorkObject:(WorkTime *)value;
- (void)addProjectWork:(NSSet *)values;
- (void)removeProjectWork:(NSSet *)values;

@end
