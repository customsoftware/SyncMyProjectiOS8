//
//  CCProjectTimer.m
//  ProjectFolio
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

-(void)timerTest{
    if (self.timer != nil ) {
        self.timer.billed = [NSNumber numberWithBool:NO];
        self.timer.start = [NSDate date];
        self.parentProject.projectUUID = (self.parentProject.projectUUID != nil) ? self.parentProject.projectUUID : [[CoreData sharedModel:nil] getUUID];
        [self.defaults saveString:self.parentProject.projectUUID atKey:kSelectedProject];
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
    self.timer = [CoreData createNewTimerForProject:self.parentProject];
    [self timerTest];
}

-(void)startTaskTimer{
    self.timer = [CoreData createNewTimerForProject:self.parentProject andTask:self.owningTask];
    [self timerTest];
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
        // NSLog(@"Timer stopped");
        self.timer = nil;
        self.parentProject = nil;
        self.owningTask = nil;
        self.defaults =nil;
    }
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
