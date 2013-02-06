//
//  CCProjectTimer.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/8/12.
//
//

#import <Foundation/Foundation.h>
#import "Project.h"
#import "WorkTime.h"
#import "CCAppDelegate.h"
#import "CCSettingsControl.h"

@interface CCProjectTimer : NSObject

-(CCProjectTimer *)init;

-(void)releaseTimer;
-(void)startTimingNameForProject:(NSNotification *)notification;

@end
