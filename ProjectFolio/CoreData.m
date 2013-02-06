//
//  CoreData.m
//  ProjectFolio
//
//  Created by Ken Cluff on 12/4/12.
//
//

#import "CoreData.h"
#import <TargetConditionals.h>
#define ManagedObjectModelFileName @"ProjectFolio"
//iCloud Parameters
#define UBIQUITY_CONTAINER_IDENTIFIER @"4MAEKVPSTZ.com.customsoftware.ProjectFolio"
#define UBIQUITY_CONTENT_NAME_KEY @"com.customsoftware.ProjectFolio.CoreData"

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
@synthesize iCloudAvailable = _iCloudAvailable;

#pragma mark - Singleton Creation
+ (id)sharedModel:(id<CoreDataDelegate>)delegate{
	@synchronized(self){
		if(sharedModel == nil)
			sharedModel = [[self alloc] initWithDelegate:delegate];
		else {
			if(delegate)
				[sharedModel.delegates addObject:delegate];
		}
	}
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
    WorkTime *time = [NSEntityDescription insertNewObjectForEntityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    [owningProject addProjectWorkObject:time];
    time.workProject = owningProject;
    time.dateCreated = [NSDate date];
    time.dateModified = time.dateCreated;
    time.timerUUID = [[CoreData sharedModel:nil] getUUID];
    
    return time;
}

+ (WorkTime *)createNewTimerForProject:(Project *)owningProject andTask:(Task *)owningTask{
    WorkTime *newTimer = [CoreData createNewTimerForProject:owningProject];
    newTimer.workTask = owningTask;
    [owningTask addTaskTimerObject:newTimer];
    return newTimer;
}


#pragma mark - Instance methods
- (id)initWithDelegate:(id<CoreDataDelegate>)newDelegate{
    self = [super init];
	if(self){
        
		_delegates = [[NSMutableArray alloc] init];
		if(newDelegate)
			[_delegates addObject:newDelegate];
		
        //Test for iCloud availability
#if TARGET_IPHONE_SIMULATOR
        NSLog(@"Running in simulator");
        self.iCloudAvailable = NO;
#else
        CCSettingsControl *settings = [[CCSettingsControl alloc] init];
        if([settings isICloudAuthorized]){
            [[NSBundle mainBundle] bundleIdentifier];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *contentURL = [fileManager URLForUbiquityContainerIdentifier:UBIQUITY_CONTAINER_IDENTIFIER];
            if(contentURL)
                self.iCloudAvailable = YES;
            else
                self.iCloudAvailable = NO;
        } else {
            self.iCloudAvailable = NO;
        }
#endif
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
    if (__managedObjectContext != nil){
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
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
            //Test for iCloud availability
            CCSettingsControl *settings = [[CCSettingsControl alloc] init];
            if([settings isICloudAuthorized]){
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(persistentStoreDidChange:)
                                                             name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                           object:coordinator];
           /*     [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mergeChangesFrom_iCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];*/
                
            }
        }];
        
        
        __managedObjectContext = moc;
    }
    return __managedObjectContext;
}

- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    
	NSManagedObjectContext* moc = [self managedObjectContext];
    
    [moc performBlock:^{
        
        [moc mergeChangesFromContextDidSaveNotification:notification];
        
        NSNotification* refreshNotification = [NSNotification notificationWithName:@"SomethingChanged"
                                                                            object:self
                                                                          userInfo:[notification userInfo]];
        
        [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    }];
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:ManagedObjectModelFileName withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator{
    if (__persistentStoreCoordinator != nil){
        return __persistentStoreCoordinator;
    }
    
    // Set up persistent Store Coordinator
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        // Set up SQLite db and options dictionary
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",@"ProjectFolio"]];
        NSDictionary * optionsDictionary = nil;
        NSError *error = nil;
        
        // If we want to use iCloud, set up
        //Test for iCloud availability
        CCSettingsControl *settings = [[CCSettingsControl alloc] init];
        if([settings isICloudAuthorized] && self.iCloudAvailable)
        {
           [[NSBundle mainBundle] bundleIdentifier];
           NSFileManager *fileManager = [NSFileManager defaultManager];
           NSURL *contentURL = [fileManager URLForUbiquityContainerIdentifier:@"4MAEKVPSTZ.com.customsoftware.ProjectFolio"];
           
           optionsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"com.customsoftware.ProjectFolio.CoreData", NSPersistentStoreUbiquitousContentNameKey,
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
       }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self userInfo:nil];
        });
   // });

    
    return __persistentStoreCoordinator;
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

@end
