//
//  WorkTime+CategoryWorkTimeQuery.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/19/13.
//
//

#import "WorkTime+CategoryWorkTimeQuery.h"

@implementation WorkTime (CategoryWorkTimeQuery)

- (NSString *)taskDay {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMDD"];
    return [formatter stringFromDate:self.start];
}

//- (NSString *)taskDay {
//    // Convert the start into a string "YYYYMMDD"
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"YYYYMMDD"];
//    return [formatter stringFromDate:self.start];
//}
//
@end
