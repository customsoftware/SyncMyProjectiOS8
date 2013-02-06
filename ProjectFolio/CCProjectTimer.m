//
//  CCProjectTimer.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/8/12.
//
//

#import "CCProjectTimer.h"
#define kStartNotification @"ProjectTimerStartNotification"
#define kStopNotification @"ProjectTimerStopNotification"
#define kSelectedProject @"activeProject"

@interface CCProjectTimer ()

@property (strong, nonatomic) WorkTime *timer;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) Project *parentProject;
@property (strong, nonatomic) CCSettingsControl *defaults;

@end

@implementation CCProjectTimer

@synthesize timer = _timer;
@synthesize formatter = _formatter;
@synthesize parentProject = _parentProject;
@synthesize defaults = _defaults;

-(CCProjectTimer *)init{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimingNameForProject:) name:kStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseTimer) name:kStopNotification object:nil];
    return self;
}

-(void)startTimer{    
    self.timer = [CoreData createNewTimerForProject:self.parentProject];
    if (self.timer != nil && [[CoreData sharedModel:nil] managedObjectContext] != nil) {
        self.timer.billed = [NSNumber numberWithBool:NO];
        self.timer.start = [[NSDate alloc]init];
        // [self.parentProject addProjectWorkObject:self.timer ];
        [self.defaults saveString:self.parentProject.projectName atKey:kSelectedProject];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Timer Failure" message:[[NSString alloc] initWithFormat:@"Timer for %@ project failed to start", self.parentProject.projectName] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
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

-(void)releaseTimer{
    if (self.timer != nil) {
        self.timer.end = [NSDate date];
        // NSLog(@"Timer stopped");
        self.timer = nil;
        self.parentProject = nil;
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
