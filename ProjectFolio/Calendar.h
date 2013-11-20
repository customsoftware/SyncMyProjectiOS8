//
//  Calendar.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

@class Project;

@interface Calendar : NSManagedObject

@property (nonatomic, retain) NSString * calendarUUID;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSString * event;
@property (nonatomic, retain) NSString * eventID;
@property (nonatomic, retain) NSDecimalNumber * interval;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSNumber * repeat;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSDate * stop;
@property (nonatomic, retain) NSSet *calendarProject;
@end

@interface Calendar (CoreDataGeneratedAccessors)

- (void)addCalendarProjectObject:(Project *)value;
- (void)removeCalendarProjectObject:(Project *)value;
- (void)addCalendarProject:(NSSet *)values;
- (void)removeCalendarProject:(NSSet *)values;

@end
