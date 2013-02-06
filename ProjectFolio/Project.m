//
//  Project.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/24/12.
//
//

#import "Project.h"
#import "Calendar.h"
#import "Deliverables.h"
#import "Priority.h"
#import "Task.h"
#import "WorkTime.h"


@implementation Project

@dynamic active;
@dynamic assignedTo;
@dynamic assignedToFirst;
@dynamic assignedToLast;
@dynamic billable;
@dynamic billed;
@dynamic complete;
@dynamic costBudget;
@dynamic dateCreated;
@dynamic dateFinish;
@dynamic dateStart;
@dynamic dueTo;
@dynamic dueToFirst;
@dynamic dueToLast;
@dynamic hourBudget;
@dynamic hourlyRate;
@dynamic isOverDue;
@dynamic projectAddressGroup;
@dynamic projectCalendarName;
@dynamic projectName;
@dynamic projectNotes;
@dynamic systemRecord;
@dynamic projectCalendar;
@dynamic projectExpense;
@dynamic projectTask;
@dynamic projectWork;
@dynamic projectPriority;

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
