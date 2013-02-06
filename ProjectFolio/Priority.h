//
//  Priority.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, Task;

@interface Priority : NSManagedObject

@property (nonatomic, retain) NSString * priority;
@property (nonatomic, retain) NSSet *priorityTask;
@property (nonatomic, retain) NSSet *priorityProject;
@end

@interface Priority (CoreDataGeneratedAccessors)

- (void)addPriorityTaskObject:(Task *)value;
- (void)removePriorityTaskObject:(Task *)value;
- (void)addPriorityTask:(NSSet *)values;
- (void)removePriorityTask:(NSSet *)values;

- (void)addPriorityProjectObject:(Project *)value;
- (void)removePriorityProjectObject:(Project *)value;
- (void)addPriorityProject:(NSSet *)values;
- (void)removePriorityProject:(NSSet *)values;

@end
