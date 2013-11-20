//
//  CCAppDelegate.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "Project.h"
#import "Priority.h"
#import "CCVisibleFixer.h"
#import "CCErrorLogger.h"
#import "CCInitializer.h"
#import "CCSettingsControl.h"
#import "CoreData.h"
#import "CCLocalData.h"
#import "iCloudStarterProtocol.h"
#import "Deliverables.h"

@interface CCAppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate,CCLoggerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) CCErrorLogger *errorLogger;
@property (strong, nonatomic) CoreData *sharedStack;

// - (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)releaseLogger;
- (BOOL)iCloudIsAvailableNow;
- (BOOL)checkIsDeviceVersionHigherThanRequiredVersion:(NSString *)requiredVersion;
- (void)registeriCloudDelegate:(id<iCloudStarterProtocol>)delegate;

@end
