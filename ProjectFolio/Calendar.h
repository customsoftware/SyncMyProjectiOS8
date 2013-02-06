//
//  Calendar.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Calendar : NSManagedObject

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
