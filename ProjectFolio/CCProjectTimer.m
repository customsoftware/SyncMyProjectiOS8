//
//  CCProjectTimer.m
//  SyncMyProject
//
//  Created by Ken Cluff on 8/8/12.
//
//

#import "CCProjectTimer.h"
#define kStartNotification @"ProjectTimerStartNotification"
#define kStartTaskNotification @"TaskTimerStartNotification"
#define kStopNotification @"ProjectTimerStopNotification"

@interface CCProjectTimer ()

@property (strong, nonatomic) WorkTime *timer;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) Project *parentProject;
@property (strong, nonatomic) Task *owningTask;
@property (strong, nonatomic) CCSettingsControl *defaults;

@end

@implementation CCProjectTimer

-(CCProjectTimer *)init{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimingNameForProject:) name:kStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimingNameForTask:) name:kStartTaskNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseTimer) name:kStopNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setActiveProject {
    self.parentProject.projectUUID = (self.parentProject.projectUUID != nil) ? self.parentProject.projectUUID : [[CoreData sharedModel:nil] getUUID];
    [self.defaults saveString:self.parentProject.projectUUID atKey:kSelectedProject];
}

-(void)timerTest{
    if (self.timer != nil ) {
        self.timer.billed = [NSNumber numberWithBool:NO];
        NSDate *storedTime = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredStopTime];
        if (storedTime != nil) {
            self.timer.start = storedTime;
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kStoredStopTime];
        } else  {
            self.timer.start = [NSDate date];
        }
        if (self.owningTask) {
            [self.defaults saveString:self.owningTask.taskUUID atKey:kSelectedTask];
        } else {
            [self.defaults saveString:@"None" atKey:kSelectedTask];
        }
        NSString *timeString = [self.formatter stringFromDate:self.timer.start];
        [self.defaults saveString:timeString atKey:kStartTime];
    } else if ( !self.parentProject ) {
        // No project selected yet, so no point to start a timer yet.
    } else {
        BOOL keyStatus = [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus];
        if (keyStatus == YES) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timer Failure" message:[[NSString alloc] initWithFormat:@"Timer for %@ project failed to start", self.parentProject.projectName] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

-(void)startTimer{
    [self setActiveProject];
    if ([self isTImerEnabledForProject:self.parentProject]) {
        self.timer = [CoreData createNewTimerForProject:self.parentProject];
        [self timerTest];
    } else {
        self.timer = nil;
    }
}

-(void)startTaskTimer{
    [self setActiveProject];
    if ([self isTImerEnabledForProject:self.parentProject]) {
        self.timer = [CoreData createNewTimerForProject:self.parentProject andTask:self.owningTask];
        [self timerTest];
    } else {
        self.timer = nil;
    }
}

#pragma mark - Public API
- (void)restartTimer {
    if (!self.timer) {
        NSString *projectUUID = [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedProject];
        NSString *taskUUID = [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedTask];
        NSString *startTime = [[NSUserDefaults standardUserDefaults] stringForKey:kStartTime];
        if (startTime != nil && projectUUID != nil && startTime.length > 0 && projectUUID.length > 0 ) {
            // We have valid time and a project. Start the timer for the project and set the start time
            //  to the stored time
            NSManagedObjectContext *context = [[CoreData sharedModel:nil] managedObjectContext];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"projectUUID == %@", projectUUID];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                      inManagedObjectContext:context];
            NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"active" ascending:NO];
            [request setEntity:entity];
            [request setSortDescriptors:@[activeDescriptor]];
            [request setPredicate:predicate];
            NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
            NSError *error = nil;
            [frc performFetch:&error];
            if (!error && frc.fetchedObjects.count > 0 ) {
                self.parentProject = frc.fetchedObjects[0];
                [self startTimer];
                self.timer.start = [self.formatter dateFromString:startTime];
            }
        }
        
        if (taskUUID != nil && ![taskUUID isEqualToString:@"None"]) {
            // Find the task and set it as the controlling task for the timer
            Task *foundTask = nil;
            for (Task *task in self.parentProject.projectTask) {
                if ([task.taskUUID isEqualToString:taskUUID]) {
                    foundTask = task;
                    break;
                }
            }
            self.timer.workTask = foundTask;
            [foundTask addTaskTimerObject:self.timer];
        }
    }
}

-(void)startTimingNameForProject:(NSNotification *)notification{
    Project *newProject = (Project *)[[notification userInfo] objectForKey:@"Project"];
    if (self.parentProject == newProject && self.timer != nil){
        // NSLog(@"Timer already running for Project: %@", self.parentProject.projectName);
    } else if ( self.timer != nil){
        [self releaseTimer];
        self.parentProject = newProject;
        [self startTimer];
    } else {
        self.parentProject = newProject;
        [self startTimer];
    }
}

-(void)startTimingNameForTask:(NSNotification *)notification{
    Project *newProject = (Project *)[[notification userInfo] objectForKey:@"Project"];
    Task *newTask = (Task *)[[notification userInfo] objectForKey:@"Task"];
    if (self.parentProject == newProject && self.timer != nil && self.owningTask == newTask){
        // NSLog(@"Timer already running for Project: %@", self.parentProject.projectName);
    } else if ( self.timer != nil){
        [self releaseTimer];
        self.parentProject = newProject;
        self.owningTask = newTask;
        [self startTaskTimer];
    } else {
        self.owningTask = newTask;
        self.parentProject = newProject;
        [self startTaskTimer];
    }
}

-(void)releaseTimer{
    if (self.timer != nil) {
        self.timer.end = [NSDate date];
        [self.timer.managedObjectContext save:nil];
        // NSLog(@"Timer stopped");
        self.timer = nil;
        self.parentProject = nil;
        self.owningTask = nil;
        self.defaults =nil;
    }
}

#pragma mark - Helpers
- (BOOL)isTImerEnabledForProject:(Project *)project {
    BOOL inactiveEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kInActiveEnabled];
    BOOL returnValue = NO;
    
    if ([project.active boolValue]) {
        returnValue = YES;
    } else if ( inactiveEnabled ) {
        returnValue = YES;
    }
    
    return returnValue;
}

#pragma mark - Lazy Getter
-(CCSettingsControl *)defaults{
    if (_defaults == nil) {
        _defaults = [[CCSettingsControl alloc] init];
    }
    return _defaults;
}

-(NSDateFormatter *)formatter{
    if (_formatter == nil) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setTimeStyle:NSDateFormatterMediumStyle];
        [_formatter setDateStyle:NSDateFormatterMediumStyle];
    }
    return _formatter;
}

@end
