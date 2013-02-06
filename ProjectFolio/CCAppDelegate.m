//
//  CCAppDelegate.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CCMasterViewController.h"

#define iCloudSynIfAvailable   YES
#define UBIQUITY_CONTAINER_IDENTIFIER @"4MAEKVPSTZ.com.customsoftware.ProjectFolio"
#define UBIQUITY_CONTENT_NAME_KEY @"com.customsoftware.ProjectFolio.CoreData"

@interface CCAppDelegate ()
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@property (nonatomic) BOOL iCloudAvailable;

@end

@implementation CCAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize eventStore = _eventStore;
@synthesize errorLogger = _errorLogger;
@synthesize projectTimer = _projectTimer;

#pragma mark - Application Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        UINavigationController *masterNavigationController = [splitViewController.viewControllers objectAtIndex:0];
        CCMasterViewController *controller = (CCMasterViewController *)masterNavigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    } else {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        CCiPhoneMasterViewController *controller = (CCiPhoneMasterViewController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
    application.applicationIconBadgeNumber = 0;
    CCVisibleFixer *fixer = [[CCVisibleFixer alloc] init];
    [fixer fixAllVisible];
    [self testPriorityConfig];
    
    return YES;
}

-(BOOL)iCloudIsAvailableNow{
    CoreData *sharedModel = [CoreData sharedModel:nil];
    return sharedModel.iCloudAvailable;
}

-(void)testPriorityConfig{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Priority" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *defaultDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: defaultDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setEntity:entity];
    NSFetchedResultsController * pFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                          managedObjectContext:self.managedObjectContext
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
    NSError *fetchError;
    [pFRC performFetch:&fetchError];
    if ([[pFRC fetchedObjects]count] == 0) {
        // This will happen only the first time the app starts up, unless the user deletes all of the settings
        Priority * newPriority = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"Priority"
                                  inManagedObjectContext:self.managedObjectContext];
        newPriority.priority = @"Low";
        [self.managedObjectContext save:&fetchError];
        newPriority = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Priority"
                       inManagedObjectContext:self.managedObjectContext];
        newPriority.priority = @"Medium";
        [self.managedObjectContext save:&fetchError];
        newPriority = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Priority"
                       inManagedObjectContext:self.managedObjectContext];
        newPriority.priority = @"High";
        [self.managedObjectContext save:&fetchError];
        [pFRC performFetch:&fetchError];
        CCInitializer *initializer = [[CCInitializer alloc] init];
        [initializer loadTestData];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
     [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Need to write the error value to an error log so the send error report can send it to me.
}

- (void)saveContext
{
    CoreData *sharedModel = [CoreData sharedModel:nil];
    [sharedModel saveContext];
    
    /* NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges])
        {
            @try {
                if (![managedObjectContext save:&error]){
                    self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                    [self.errorLogger releaseLogger];
                }
            }
            @catch (NSException *exception) {
                self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.errorLogger releaseLogger];
            }
        } 
    }*/
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    [[[UIAlertView alloc]initWithTitle:@"Local Notification" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    application.applicationIconBadgeNumber = 0;
}

#pragma mark - Calendar components
-(EKEventStore *)eventStore{
    if (_eventStore == nil) {
        _eventStore = [[EKEventStore alloc]init];}
    return _eventStore;
}


#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext == nil)
    {
        CoreData *sharedModel = [CoreData sharedModel:nil];
        __managedObjectContext = sharedModel.managedObjectContext;
        
        /*NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil){
            
            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc]
                                           initWithConcurrencyType:NSMainQueueConcurrencyType];
            
            [moc performBlockAndWait:^(void){
                // Set up an undo manager, not included by default
                NSUndoManager *undoManager = [[NSUndoManager alloc] init];
                [undoManager setGroupsByEvent:NO];
                [moc setUndoManager:undoManager];
                
                
                // Set persistent store
                [moc setPersistentStoreCoordinator:coordinator];
                
                //icloud
                if(self.iCloudAvailable){
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(persistentStoreDidChange:)
                                                                 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                               object:coordinator];
                }
            }];
            __managedObjectContext = moc;
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Core Data Failure" message:@"The Persistent store coordinator failed to create. You do not have core data." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }*/
    }

    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel == nil)
    {
        CoreData *sharedModel = [CoreData sharedModel:nil];
        __managedObjectModel = sharedModel.managedObjectModel;
    }
    /*NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ProjectFolio" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];*/
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator == nil)
    {
        CoreData *sharedModel = [CoreData sharedModel:nil];
        __persistentStoreCoordinator = sharedModel.persistentStoreCoordinator;
    }
    
    /*NSError *error = nil;

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ProjectFolio.sqlite"];
    
    NSDictionary * optionsDictionary = nil;
    if (iCloudSynIfAvailable && self.iCloudAvailable) {
        [[NSBundle mainBundle] bundleIdentifier];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *contentURL = [fileManager URLForUbiquityContainerIdentifier:UBIQUITY_CONTAINER_IDENTIFIER];

        optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                             UBIQUITY_CONTENT_NAME_KEY, NSPersistentStoreUbiquitousContentNameKey,
                             contentURL, NSPersistentStoreUbiquitousContentURLKey, 
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    } else {
        optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:YES],
                                            NSMigratePersistentStoresAutomaticallyOption,
                                            [NSNumber numberWithBool:YES],
                                            NSInferMappingModelAutomaticallyOption,
                                            nil];
    }
    
   @try {
       
        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:optionsDictionary error:&error]){
            self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.errorLogger releaseLogger];
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.fireDate = [NSDate date];
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.alertAction = @"Database Creation Failure Alert";
            notification.alertBody = @"You didn't do anything wrong, but the app failed to create the database needed to operate. Please send a bug report to the developer. Thanks.";
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.applicationIconBadgeNumber = notification.applicationIconBadgeNumber + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Core Data Error" message:@"Creation of persistent store failed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    @catch (NSException *exception) {
        self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
        [self.errorLogger releaseLogger];
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate date];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.alertAction = @"Database Creation Failure Alert";
        notification.alertBody = @"You didn't do anything wrong, but the app failed to create the database needed to operate. Please send a bug report to the developer. Thanks.";
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = notification.applicationIconBadgeNumber + 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }*/
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Error Logging
-(void)releaseLogger{
    self.errorLogger = nil;
}

#pragma mark - iCloud Functionality

- (void)persistentStoreDidChange:(NSNotification*)notification{
    NSLog(@"Change Detected!");
    [__managedObjectContext performBlockAndWait:^(void){
        [__managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        
        /*for(id<CoreDataDelegate>delegate in _delegates){
            if([delegate respondsToSelector:@selector(persistentStoreDidChange)])
                [delegate persistentStoreDidChange];
        }*/
    }];
}


@end
