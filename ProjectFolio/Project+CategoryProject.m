//
//  Project+CategoryProject.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import "Project+CategoryProject.h"

@interface Project ()

@property (strong, nonatomic) NSNumber *remaining;

@end



@implementation Project (CategoryProject)

-(NSNumber *)isOverDue{
    BOOL isProjectOverDue = NO;
    
    NSDate *today = [NSDate date];
    if (self.dateFinish != nil) {
        if ([self.dateFinish compare:today] == NSOrderedAscending){
            isProjectOverDue = YES;
        }
    }
    return  [NSNumber numberWithBool:isProjectOverDue];
}

- (NSNumber *)remainingHours {
    // Get total amount of time spent
    float projectTime = [self.hourBudget floatValue];
    float actualTime = 0.0;
    float returnValue = 0.0;
    if (projectTime > 0 && self.projectWork.count > 0) {
        for (WorkTime *timer in self.projectWork) {
            actualTime += [timer.elapseTime integerValue];
        }
        
        actualTime = actualTime/3600;
        returnValue = actualTime/projectTime;
    }
    
    // Get project time
    return [NSNumber numberWithFloat:returnValue];
}

@end
