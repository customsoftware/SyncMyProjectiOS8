//
//  CCAppDelegate.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CCMasterViewController.h"
#import "CCDetailViewController.h"
#import "CCiPhoneMasterViewController.h"
#import "CCIAPCards.h"
#import "CCProjectTimer.h"

#define iCloudSynIfAvailable   YES

@interface CCAppDelegate ()
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@property (nonatomic) BOOL iCloudAvailable;
@property (strong, nonatomic) NSArray *delegateList;

@end

@implementation CCAppDelegate

#pragma mark - Application Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setAppID];
    self.delegateList = [[NSArray alloc] init];
    // Override point for customization after application launch.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(kvStoreWillChange:)
                   name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(kvStoreDidChange:)
                   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                 object:[NSUbiquitousKeyValueStore defaultStore]];
    [center addObserver:self
               selector:@selector(kvContainerDidChange:)
                   name:NSUbiquityIdentityDidChangeNotification
                 object:nil];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    // Override point for customization after application launch.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    self.sharedStack = [CoreData sharedModel:nil];
    application.applicationIconBadgeNumber = 0;
    CCVisibleFixer *fixer = [[CCVisibleFixer alloc] init];
    [fixer fixAllVisible];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *storedVersion = [defaults objectForKey:(NSString *)kCFBundleVersionKey];
    
    if (![storedVersion isEqualToString:version]) {
        [defaults setBool:NO forKey:@"dontShowNewsAgain"];
        [defaults setObject:version forKey:(NSString *)kCFBundleVersionKey];
        [defaults setBool:YES forKey:kHelpTest];
    } else {
        [defaults setBool:NO forKey:kHelpTest];
    }
    
    float redTest = [defaults floatForKey:kRedNameKey];
    float blueTest = [defaults floatForKey:kBlueNameKey];
    if (redTest == 0 && blueTest == 0) {
        [defaults setFloat:.95f forKey:kRedNameKey];
        [defaults setFloat:.85f forKey:kGreenNameKey];
        [defaults setFloat:.85f forKey:kBlueNameKey];
        [defaults setFloat:1.0f forKey:kSaturation];
        [defaults setInteger:18 forKey:kFontSize];
        [defaults setObject:@"Optima" forKey:kFontNameKey];
        [defaults setInteger:2 forKey:kRatingCounterReferenceKey];
        [defaults setInteger:0 forKey:kRatingCounterKey];
    }
   
    [self setButtonStateWithShow:NO];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Reinstate the timer. Find the latest timer event. If it has a null end time
    
    return YES;
}

-(BOOL)iCloudIsAvailableNow{
    CoreData *sharedModel = [CoreData sharedModel:nil];
    return sharedModel.iCloudAvailable;
}

-(void)setButtonStateWithShow:(BOOL)show{
    BOOL keyStatus = [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus];
    NSString *localDeviceGUID = [[NSUserDefaults standardUserDefaults] objectForKey:kAppString];
    
    // Get Cloud status
    NSString *controllingAppID = nil;
    NSDictionary *cloudDictionary = [[CoreData sharedModel:nil] cloudDictionary];
    if (cloudDictionary != nil && [cloudDictionary valueForKey:kAppString]) {
        controllingAppID = [cloudDictionary valueForKey:kAppString];
    }
    
    if ([localDeviceGUID isEqualToString:controllingAppID]){
        keyStatus = YES;
    } else {
        if (keyStatus == YES) {
            if (show == YES) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Project Timer Status" message:@"Timer is disabled for this device. To enable it, go into settings and enable the timer." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                [alert show];
            }
        }
        keyStatus = NO;
    }
    [[NSUserDefaults standardUserDefaults] setBool:keyStatus forKey:kAppStatus];
}

- (void) setAppID{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *deviceGUID = [settings stringForKey:kAppString];
    
    if (!deviceGUID) {
        deviceGUID = [[CoreData sharedModel:nil] getUUID];
        [settings setValue:deviceGUID forKey:kAppString];
    }
}

- (BOOL)checkIsDeviceVersionHigherThanRequiredVersion:(NSString *)requiredVersion
{
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:requiredVersion options:NSNumericSearch] != NSOrderedAscending)
    {
        return YES;
    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
     [[CoreData sharedModel:nil] saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
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
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
//    [self setButtonStateWithShow:YES];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kStoredStopTime];
    NSNotification *stopTimer = [NSNotification notificationWithName:kStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:stopTimer];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    [[CoreData sharedModel:nil] saveContext];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // Need to write the error value to an error log so the send error report can send it to me.
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    [[[UIAlertView alloc]initWithTitle:@"Local Notification" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    application.applicationIconBadgeNumber = 0;
}

-(void)kvStoreDidChange:(NSNotification *)notification{
    CCLocalData *localData = [[CCLocalData alloc] init];
    [localData kvStoreDidChange:notification];
}

-(void)kvContainerDidChange:(NSNotification *)notification{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Remote Storage Status Changed" message:@"The state of the remote iCloud storage has changed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)kvStoreWillChange:(NSNotification *)notification{
    // Need to make certain this happens on the main thread since we're updating UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
        
        for (id<iCloudStarterProtocol> delegate in self.delegateList) {
            [delegate respondToiCloudUpdate];
        }
    });
}

#pragma mark - API
- (void)registeriCloudDelegate:(id<iCloudStarterProtocol>)delegate {
    BOOL isInArray = NO;
    
    for (id<iCloudStarterProtocol> storedDelegate in self.delegateList) {
        if (storedDelegate == delegate) {
            isInArray = YES;
            break;
        }
    }
    
    if (!isInArray) {
        NSMutableArray *newArray = [self.delegateList mutableCopy];
        [newArray addObject:delegate];
        self.delegateList = [newArray copy];
    }
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
