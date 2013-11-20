//
//  Project+CategoryProject.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import "Project+CategoryProject.h"

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


@end
