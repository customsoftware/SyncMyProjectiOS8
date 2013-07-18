//
//  CCTaskDueDateViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import "CCTaskDueDateViewController.h"
#import "Project.h"
#import "CCCalendarControlViewController.h"

@interface CCTaskDueDateViewController ()

@property (strong, nonatomic) CCCalendarControlViewController *calendarControl;

@end

@implementation CCTaskDueDateViewController

@synthesize dueDate = _dueDate;
@synthesize activeTask = _activeTask;

#pragma mark - IBAction

-(IBAction)setTaskDueDate:(UIDatePicker *)sender{
    self.activeTask.dueDate = sender.date;
}

-(IBAction)changeDueDate:(UISegmentedControl *)sender{
    int interval = 0;
    switch (sender.selectedSegmentIndex) {
        case EXACT:
            interval = -HOUR_BEFORE;
            break;
            
        case ONE_HOUR:
            interval = -DAY_BEFORE;
            break;
            
        case ONE_DAY:
            interval = -WEEK_BEFORE;
            break;
            
        case ONE_WEEK:
            interval = -(4 * WEEK_BEFORE );
            break;
            
        default:
            break;
    }
    self.dueDate.date = [self.dueDate.date dateByAddingTimeInterval:interval];
    self.activeTask.dueDate = self.dueDate.date;
}

-(IBAction)pushIntoReminder:(UISegmentedControl *)sender{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    int interval = 0;
    switch (sender.selectedSegmentIndex) {
        case EXACT:
            interval = 0;
            break;
            
        case ONE_HOUR:
            interval = HOUR_BEFORE;
            break;
            
        case ONE_DAY:
            interval = DAY_BEFORE;
            break;
            
        case ONE_WEEK:
            interval = WEEK_BEFORE;
            break;
            
        default:
            break;
    }
    notification.fireDate = [self.dueDate.date dateByAddingTimeInterval:interval];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = [[NSString alloc] initWithFormat:@"%@ is due now", self.activeTask.title];
    notification.alertAction = @"Alert";
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)cancelDueDate{
    self.activeTask.dueDate = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Life cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDueDate)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    self.calendarControl = [[CCCalendarControlViewController alloc] init];
    [self.calendarControl.view setFrame:(CGRectMake(0, 300, 320, 300))];
    [self.calendarControl.view setHidden:FALSE];
}

-(void)viewWillAppear:(BOOL)animated{
    if (self.activeTask.dueDate == nil) {
        self.activeTask.dueDate = [NSDate date];
    }
    self.dueDate.date = self.activeTask.dueDate;
    self.dueDate.minimumDate = self.activeTask.taskProject.dateStart;    
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        self.activeTask.taskProject.dateFinish = self.activeTask.dueDate;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    if (self.activeTask.taskProject.dateFinish == nil && self.activeTask.dueDate != nil){
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        
        NSString *messageString = [[NSString alloc]initWithFormat:@"The project finish date hasn't been set. Would you like to use this date %@ as the finish date?", [formatter stringFromDate:self.activeTask.dueDate]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Set Project Finish Date Reminder" message:messageString delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.dueDate = nil;
    self.activeTask = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
