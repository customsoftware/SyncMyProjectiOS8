//
//  WorkTime.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface WorkTime : NSManagedObject

@property (nonatomic, retain) NSNumber * billed;
@property (nonatomic, retain) NSDate * dateBilled;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSNumber * elapseTime;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) Project *workProject;

@end
