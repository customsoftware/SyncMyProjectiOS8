//
//  CCProjectTaskDelegate.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/21/12.
//
//

#import "Project.h"
#import "Task.h"

@protocol CCProjectTaskDelegate <NSObject>

-(Project *)getActiveProject;

@optional
-(Task *)getSelectedTask;
-(Project *)getControllingProject;

@end
