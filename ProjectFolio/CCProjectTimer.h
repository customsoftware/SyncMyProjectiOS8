//
//  CCProjectTimer.h
//  SyncMyProject
//
//  Created by Ken Cluff on 8/8/12.
//
//

#import "Project.h"
#import "WorkTime.h"
#import "CCAppDelegate.h"
#import "CCSettingsControl.h"

@interface CCProjectTimer : NSObject

-(CCProjectTimer *)init;

-(void)releaseTimer;
-(void)startTimingNameForProject:(NSNotification *)notification;
-(void)startTimingNameForTask:(NSNotification *)notification;
-(void)restartTimer;

@end
