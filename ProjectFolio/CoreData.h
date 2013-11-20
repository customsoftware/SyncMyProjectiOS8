//
//  CoreData.h
//  SyncMyProject
//
//  Created by Ken Cluff on 12/4/12.
//
//

#import "Project.h"
// #import "Deliverables.h"
#import "WorkTime.h"
#import "Task.h"
#import "Calendar.h"
#import "Category.h"
#import "CCErrorLogger.h"
#import "CCSettingsControl.h"
#import "CCLocalData.h"

#define kiCloudSyncNotification @"SomethingChanged"

@protocol CoreDataDelegate <NSObject>
- (void)persistentStoreDidChange;

@end

@interface CoreData : NSObject<CCLoggerDelegate> {
    
}
@property (strong, nonatomic) NSUbiquitousKeyValueStore *iCloudKey;
@property (nonatomic, strong) NSMutableArray *delegates;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSFetchedResultsController *projectFRC;

//Chapter 3: iCloud
@property (nonatomic) BOOL iCloudAvailable;

// Singleton Creation
+ (id)sharedModel:(id<CoreDataDelegate>)delegate;

#pragma mark - Class methods
+ (id)allocWithZone:(NSZone *)zone;
+ (void)addDelegate:(id<CoreDataDelegate>)delegate;
+ (void)removeDelegate:(id<CoreDataDelegate>)delegate;
+ (Project *)createProjectWithName:(NSString *)newProjectName;
+ (Task *)createTask:(NSString *)newTask inProject:(Project *)owningProject;
+ (Deliverables *)createExpenseInProject:(Project *)owningProject;
+ (WorkTime *)createNewTimerForProject:(Project *)owningProject;
+ (WorkTime *)createNewTimerForProject:(Project *)owningProject andTask:(Task *)owningTask;

#pragma mark - Instance methods
- (id)saveLastModified:(id)recordObject;
- (id)initWithDelegate:(id<CoreDataDelegate>)newDelegate;
- (void)testPriorityConfig;
- (void)testProjectCount;

// Context Operations
- (void)undo;
- (void)redo;
- (void)rollback;
- (void)reset;
- (BOOL)saveContext;
- (NSString * )getUUID;

#pragma mark - Accessors
-(NSFetchedResultsController *)projectsFRCwithSortDescriptors:(NSArray *)sortDescriptors andFetchRequest:(NSFetchRequest *)request andDelegate:(id)delegate;

/*
- (NSArray*)remindersWithTitle:(NSString*)title;
- (NSArray*)notificationsWithFireDate:(NSDate*)date;

- (Reminder*)makeReminderWithTitle:(NSString *)title;
- (Notification*)makeNotificationWithFireDate:(NSDate*)fireDate;

- (BOOL)removeReminders:(NSArray*)reminders;
- (BOOL)removeAllReminders;
- (BOOL)removeNotifications:(NSArray*)notifications;
- (BOOL)removeAllNotifications;
*/

// Core Data Utilities
- (NSURL *)applicationDocumentsDirectory;

@end


