//
//  CCProjectTaskDelegate.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/21/12.
//
//

#import <Foundation/Foundation.h>
#import "Project.h"
#import "Task.h"

@protocol CCProjectTaskDelegate <NSObject>

-(Project *)getActiveProject;

@optional
-(Task *)getSelectedTask;
-(Project *)getControllingProject;

@end
