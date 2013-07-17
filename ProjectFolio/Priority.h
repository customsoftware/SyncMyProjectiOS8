//
//  Priority.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/17/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, Task;

@interface Priority : NSManagedObject

@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * priority;
@property (nonatomic, retain) NSString * priorityUUID;
@property (nonatomic, retain) NSSet *priorityProject;
@property (nonatomic, retain) NSSet *priorityTask;
@end

@interface Priority (CoreDataGeneratedAccessors)

- (void)addPriorityProjectObject:(Project *)value;
- (void)removePriorityProjectObject:(Project *)value;
- (void)addPriorityProject:(NSSet *)values;
- (void)removePriorityProject:(NSSet *)values;

- (void)addPriorityTaskObject:(Task *)value;
- (void)removePriorityTaskObject:(Task *)value;
- (void)addPriorityTask:(NSSet *)values;
- (void)removePriorityTask:(NSSet *)values;

@end
