//
//  CoreData.m
//  SyncMyProject
//
//  Created by Ken Cluff on 12/4/12.
//
//

#import "CoreData.h"
#import <TargetConditionals.h>
#import "Priority.h"
#import "CCInitializer.h"
#import "CCIAPCards.h"

@interface CoreData()

@property (strong, nonatomic) CCErrorLogger *errorLogger;

@end


static CoreData *sharedModel = nil;

@implementation CoreData
@synthesize delegates = _delegates;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize errorLogger = _errorLogger;
@synthesize projectFRC = _projectFRC;

//iCloud
#pragma mark - Singleton Creation
+ (id)sharedModel:(id<CoreDataDelegate>)delegate{
    static CoreData *sharedModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		if(sharedModel == nil) {
			sharedModel = [[self alloc] initWithDelegate:delegate];
            id currentICloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
            if (currentICloudToken) {
                NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:currentICloudToken];
                [[NSUserDefaults standardUserDefaults] setObject:newTokenData forKey:kAppBundleName];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAppBundleName];
            }
		} else {
			if(delegate)
				[sharedModel.delegates addObject:delegate];
		}
    });
    return sharedModel;
}

#pragma mark - Class Methods
+ (id)allocWithZone:(NSZone *)zone{
    @synchronized(self) {
        if(sharedModel == nil)  {
            sharedModel = [super allocWithZone:zone];
            return sharedModel;
        }
    }
    return nil;
}
+ (void)addDelegate:(id<CoreDataDelegate>)delegate{
	[sharedModel.delegates addObject:delegate];
}
+ (void)removeDelegate:(id<CoreDataDelegate>)delegate{
	[sharedModel.delegates removeObjectIdenticalTo:delegate];
}

+ (Project *)createProjectWithName:(NSString *)newProjectName{
    Project *newProject = [NSEntityDescription
                           insertNewObjectForEntityForName:@"Project"
                           inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newProject.projectName = newProjectName;
    newProject.dateCreated = [NSDate date];
    newProject.dateModified = newProject.dateCreated;
    newProject.projectUUID = [[CoreData sharedModel:nil] getUUID];
    
    return newProject;
}

+ (Task *)createTask:(NSString *)newTask inProject:(Project *)owningProject{
    Task *theNewTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    theNewTask.completed = [NSNumber numberWithBool:NO];
    theNewTask.taskProject = owningProject;
    [owningProject addProjectTaskObject:theNewTask];
    theNewTask.title = newTask;
    theNewTask.level = [NSNumber numberWithInt:0];
    theNewTask.dateCreated = [NSDate date];
    theNewTask.dateModified = theNewTask.dateCreated;
    theNewTask.taskUUID = [[CoreData sharedModel:nil] getUUID];
    
    return theNewTask;
}

+ (Deliverables *)createExpenseInProject:(Project *)owningProject{
    Deliverables *newDeliverable = [NSEntityDescription insertNewObjectForEntityForName:@"Expense" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newDeliverable.expenseProject = owningProject;
    [owningProject addProjectExpenseObject:newDeliverable];
    newDeliverable.dateCreated = [NSDate date];
    newDeliverable.dateModified = newDeliverable.dateCreated;
    newDeliverable.expenseUUID = [[CoreData sharedModel:nil] getUUID];
    
    return newDeliverable;
}

+ (WorkTime *)createNewTimerForProject:(Project *)owningProject{
    WorkTime *time = nil;
    BOOL keyStatus = [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus];
    if (keyStatus == YES && owningProject ) {
        // If the last timer has a null end date, just use it.
        NSArray *result = [[owningProject.projectWork allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"start" ascending:NO]]];
        WorkTime *timer = (WorkTime *)result.firstObject;
        if (timer.end || result.count == 0 ) {
            time = [NSEntityDescription insertNewObjectForEntityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            [owningProject addProjectWorkObject:time];
            time.workProject = owningProject;
            time.dateCreated = [NSDate date];
            time.dateModified = time.dateCreated;
            time.timerUUID = [[CoreData sharedModel:nil] getUUID];
        } else {
            time = timer;
        }
    }
    return time;
}

+ (WorkTime *)createNewTimerForProject:(Project *)owningProject andTask:(Task *)owningTask{
    WorkTime *newTimer = nil;
    BOOL keyStatus = [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus];
    if (keyStatus == YES) {
        newTimer = [CoreData createNewTimerForProject:owningProject];
        newTimer.workTask = owningTask;
        [owningTask addTaskTimerObject:newTimer];
    }
    return newTimer;
}

#pragma mark - Instance methods
- (id)saveLastModified:(id)recordObject{
    // Not many times I think it's appropriate to use an embedded return, but this is one of them
    if (!recordObject) {
        return recordObject;
    } else {
        if ([recordObject isKindOfClass:[Project class]] == YES) {
            Project * retValue = (Project *)recordObject;
            retValue.dateModified = [NSDate date];
            retValue.projectUUID = (retValue.projectUUID != nil) ? retValue.projectUUID : [self getUUID];
            return retValue;
        } else if ([recordObject isKindOfClass:[Task class]] == YES) {
            Task * retValue = (Task *)recordObject;
            retValue.dateModified = [NSDate date];
            retValue.taskUUID = (retValue.taskUUID != nil) ? retValue.taskUUID : [self getUUID];
            return retValue;
        } else if ([recordObject isKindOfClass:[WorkTime class]] == YES) {
            WorkTime * retValue = (WorkTime *)recordObject;
            retValue.dateModified = [NSDate date];
            retValue.timerUUID = (retValue.timerUUID != nil) ? retValue.timerUUID : [self getUUID];
            return retValue;
        } else if ([recordObject isKindOfClass:[Deliverables class]] == YES) {
            Deliverables * retValue = (Deliverables *)recordObject;
            retValue.dateModified = [NSDate date];
            retValue.expenseUUID = (retValue.expenseUUID != nil) ? retValue.expenseUUID : [self getUUID];
            return retValue;
        }
    }
    
    return recordObject;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Instance methods
- (id)initWithDelegate:(id<CoreDataDelegate>)newDelegate{
    self = [super init];
	if(self){
        
		_delegates = [[NSMutableArray alloc] init];
		if(newDelegate)
			[_delegates addObject:newDelegate];
		
        //Test for iCloud availability
/*#if TARGET_IPHONE_SIMULATOR
        NSLog(@"Running in simulator");
        self.iCloudAvailable = NO;
#else*/
        CCSettingsControl *settings = [[CCSettingsControl alloc] init];
        if([settings isICloudAuthorized]){
            _iCloudKey = [NSUbiquitousKeyValueStore defaultStore];
            [[NSBundle mainBundle] bundleIdentifier];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *contentURL = [fileManager URLForUbiquityContainerIdentifier:[CCLocalData ubiquityContainerID]];
            if (contentURL)
                self.iCloudAvailable = YES;
            else
                self.iCloudAvailable = NO;
        } else {
            self.iCloudAvailable = NO;
        }
//#endif
        __managedObjectContext = [self managedObjectContext];
	}
	return self;
}

- (NSString *)getUUID{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSString* returnString = (__bridge_transfer NSString*)string;
    CFRelease(theUUID);
    return returnString;
}

#pragma mark - Accessors
-(NSFetchedResultsController *)projectsFRCwithSortDescriptors:(NSArray *)sortDescriptors andFetchRequest:(NSFetchRequest *)request andDelegate:(id)delegate{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    [request setFetchBatchSize:20];
    [request setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    aFetchedResultsController.delegate = delegate;
    return aFetchedResultsController;
}

#pragma mark - Undo/Redo Operations
- (void)undo{
    [__managedObjectContext undo];
}

- (void)redo{
    [__managedObjectContext redo];
}

- (void)rollback{
    [__managedObjectContext rollback];
}

- (void)reset{
    [__managedObjectContext reset];
}

#pragma mark - Core Data stack
/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext{
    if (!__managedObjectContext){
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator){
            
            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc]
                                           initWithConcurrencyType:NSMainQueueConcurrencyType];
            
            [moc performBlockAndWait:^(void){
                // Set up an undo manager, not included by default
                NSUndoManager *undoManager = [[NSUndoManager alloc] init];
                [undoManager setGroupsByEvent:NO];
                [moc setUndoManager:undoManager];
                
                
                // Set persistent store
                [moc setPersistentStoreCoordinator:coordinator];
                [moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
                
                //icloud
                //Test for iCloud availability
                CCSettingsControl *settings = [[CCSettingsControl alloc] init];
                if([settings isICloudAuthorized]){
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(persistentStoreDidChange:)
                                                                 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                               object:coordinator];
                    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mergeChangesFrom_iCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
                    
                }
            }];
            
            
            __managedObjectContext = moc;
        }
    }
    return __managedObjectContext;
}

- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    
	NSManagedObjectContext* moc = [self managedObjectContext];
    if (moc) {
        [moc performBlock:^{
            [moc mergeChangesFromContextDidSaveNotification:notification];
            [moc processPendingChanges];
            NSNotification* refreshNotification = [NSNotification notificationWithName:kiCloudSyncNotification
                                                                                object:self
                                                                              userInfo:[notification userInfo]];
            [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
        }];
    }
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel{
    if (!__managedObjectModel ) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[CCLocalData appID] withExtension:@"momd"];
        __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator{
    if (!__persistentStoreCoordinator) {
        // Set up persistent Store Coordinator
        __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            // Set up SQLite db and options dictionary
            NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",@"synctask"]];
            NSDictionary * optionsDictionary = nil;
            NSError *error = nil;
            NSURL *cloudURL = [[ NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];

            // If we want to use iCloud, set up
            //Test for iCloud availability
            CCSettingsControl *settings = [[CCSettingsControl alloc] init];
            if([settings isICloudAuthorized] && self.iCloudAvailable && cloudURL)
            {
                NSString* coreDataCloudContent = [[ cloudURL path] stringByAppendingPathComponent:kAppName];
                cloudURL = [NSURL fileURLWithPath:coreDataCloudContent];
                
                optionsDictionary = @{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES],
                                      NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES],
                                      NSPersistentStoreUbiquitousContentNameKey:@"syncTaskCoreData",
                                      NSPersistentStoreUbiquitousContentURLKey:cloudURL,
                                      };
            } else {
                optionsDictionary = @{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES],
                                      NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES] };
            }
            
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
           } else {
               dispatch_async(dispatch_get_main_queue(), ^{
                   [[NSNotificationCenter defaultCenter] postNotificationName:kiCloudSyncNotification object:self userInfo:nil];
                   self.iCloudAvailable = YES;
               });
           }
       });
    }
    return __persistentStoreCoordinator;
}

-(void)testPriorityConfig{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kHelpTest]) {
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
        if ([pFRC fetchedObjects].count == 0) {
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
        }
    }
}
-(void)testProjectCount{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kHelpTest]) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        NSSortDescriptor *defaultDescriptor = [[NSSortDescriptor alloc] initWithKey:@"projectName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: defaultDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setEntity:entity];
        NSFetchedResultsController * pFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                                                  sectionNameKeyPath:nil
                                                                                           cacheName:nil];
        NSError *fetchError;
        [pFRC performFetch:&fetchError];
        if ([pFRC fetchedObjects].count == 0) {
            // This will happen only the first time the app starts up, unless the user deletes all of the settings
            
            NSString* path = [[NSBundle mainBundle] pathForResource:@"HowTo" ofType:@"txt"];
            
            NSString* content = [NSString stringWithContentsOfFile:path
                                                          encoding:NSUTF8StringEncoding
                                                             error:NULL];
            Project * newProject = [NSEntityDescription
                                      insertNewObjectForEntityForName:@"Project"
                                      inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Basic Instructions";
            newProject.projectNotes = content;
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            newProject.dateFinish = [NSDate date];
            newProject.complete = [NSNumber numberWithBool:YES];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            // How to add
            newProject = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Project"
                                    inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Swipe down fm nav bar adds";
            newProject.projectNotes = @"Swipe down from navigation bar to add a new record";
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            // How to delete
            newProject = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Project"
                          inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Swipe left to delete";
            newProject.projectNotes = @"Swipe left on record to delete it";
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            newProject.dateFinish = [NSDate date];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            // How to see details
            newProject = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Project"
                          inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Swipe right for details";
            newProject.projectNotes = @"Swipe right on record to see details of the record or notes.";
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            newProject.dateFinish = [NSDate date];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            // Enable Timer
            newProject = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Project"
                          inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Enable timer in Settings";
            newProject.projectNotes = @"Tap on the settings button, the gear icon. Enable timing with the 'Enable Project Timer' switch.";
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            newProject.dateFinish = [NSDate date];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            // Off-Clock entry
            newProject = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Project"
                          inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newProject.projectName = @"Off-Clock";
            newProject.projectNotes = @"Keep this project around to record time when you don't need or want to record time.";
            newProject.dateCreated = [NSDate date];
            newProject.dateStart = [NSDate date];
            newProject.dateFinish = [NSDate date];
            [[[CoreData sharedModel:nil] managedObjectContext] save:&fetchError];
            [pFRC performFetch:&fetchError];
        }
    }
}

#pragma mark - Application's Documents directory
/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Error Logging
-(void)releaseLogger{
    self.errorLogger = nil;
}

#pragma mark - Managed Object Context
- (BOOL)saveContext{
    BOOL retValue = YES;
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges])
        {
            NSArray *updateSet = [[self.managedObjectContext updatedObjects] allObjects];
            for (int x = 0; x < updateSet.count; x++) {
                id record = updateSet[x];
                record = [self saveLastModified:record];
            }
            
            NSArray *insertSet = [[self.managedObjectContext insertedObjects] allObjects];
            for (int x = 0; x < [[self.managedObjectContext insertedObjects] count]; x++) {
                id record = insertSet[x];
                record = [self saveLastModified:record];
            }
            
            @try {
                if (![managedObjectContext save:&error]){
                    self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                    [self.errorLogger releaseLogger];
                    retValue = NO;
                }
            }
            @catch (NSException *exception) {
                self.errorLogger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.errorLogger releaseLogger];
                retValue = NO;
            }
        } else {
            retValue = YES;
        }
    } else {
        retValue = NO;
    }
    
    return retValue;
}

#pragma mark - iCloud Functionality
- (void)persistentStoreDidChange:(NSNotification*)notification{
    [__managedObjectContext performBlockAndWait:^(void){
        [__managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        if (self.projectFRC != nil) {
            NSError *error = nil;
            [self.projectFRC performFetch:&error];
        }
        
        for(id<CoreDataDelegate>delegate in _delegates){
            if([delegate respondsToSelector:@selector(persistentStoreDidChange)])
                [delegate persistentStoreDidChange];
        }
    }];
}

-(NSDictionary *)cloudDictionary{
    [self.iCloudKey synchronize];
    return self.iCloudKey.dictionaryRepresentation;
}

@end
