//
//  WorkTime.m
//  
//
//  Created by Kenneth Cluff on 10/19/13.
//
//

#import "WorkTime.h"
#import "Project.h"
#import "Task.h"


@implementation WorkTime

@dynamic billed;
@dynamic dateBilled;
@dynamic dateCreated;
@dynamic dateModified;
@dynamic displayOrder;
@dynamic elapseTime;
@dynamic end;
@dynamic start;
@dynamic timerUUID;
@dynamic taskDay;
@dynamic workProject;
@dynamic workTask;

- (NSString *)taskDay {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMDD"];
    return [formatter stringFromDate:self.start];
}

@end
