//
//  CCAppDelegate.h
//  ProjectFolio
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

@interface CCAppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate,CCLoggerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) CCErrorLogger *errorLogger;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)releaseLogger;
- (BOOL)iCloudIsAvailableNow;
@end
