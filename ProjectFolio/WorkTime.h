//
//  WorkTime.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

@class Project, Task;

@interface WorkTime : NSManagedObject

@property (nonatomic, retain) NSNumber * billed;
@property (nonatomic, retain) NSDate * dateBilled;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSNumber * elapseTime;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * timerUUID;
@property (nonatomic, retain) Project *workProject;
@property (nonatomic, retain) Task *workTask;

@end
