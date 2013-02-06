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
/*
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
*/
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
        controller.managedObjectContext = [[CoreData sharedModel:nil] managedObjectContext];
    } else {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        CCiPhoneMasterViewController *controller = (CCiPhoneMasterViewController *)navigationController.topViewController;
        controller.managedObjectContext = [[CoreData sharedModel:nil] managedObjectContext];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Priority" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *defaultDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: defaultDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setEntity:entity];
    NSFetchedResultsController * pFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                          managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
    NSError *fetchError;
    [pFRC performFetch:&fetchError];
    if ([[pFRC fetchedObjects]count] == 0) {
        // This will happen only the first time the app starts up, unless the user deletes all of the settings
        Priority * newPriority = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"Priority"
                                  inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        newPriority.priority = @"Low";
        [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
        newPriority = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Priority"
                       inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        newPriority.priority = @"Medium";
        [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
        newPriority = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Priority"
                       inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        newPriority.priority = @"High";
        [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
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
     [[CoreData sharedModel:nil] saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[CoreData sharedModel:nil] saveContext];
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
    [[CoreData sharedModel:nil] saveContext];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Need to write the error value to an error log so the send error report can send it to me.
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

@end
