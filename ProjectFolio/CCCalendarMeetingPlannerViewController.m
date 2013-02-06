//
//  CCCalendarMeetingPlannerViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import "CCCalendarMeetingPlannerViewController.h"

@interface CCCalendarMeetingPlannerViewController ()

@end

@implementation CCCalendarMeetingPlannerViewController

@synthesize eventName = _eventName;
@synthesize meeting = _meeting;
@synthesize managedObjectContext = _managedObjectContext;

-(IBAction)showEventName:(UITextField *)eventName{
    self.meeting.event = eventName.text;
}

-(IBAction)setMeetingStartTime:(UIDatePicker *)sender{
    self.meeting.start = sender.date;
}

-(IBAction)pushIntoCalendar:(UIButton *)sender{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Coming Feature" message:@"This will push meeting into iPad Calendar" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)cancelDueDate{
    self.meeting.event = @"Delete me";
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.eventName.text = self.meeting.event;
    self.startTime.date = self.meeting.start;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.view endEditing:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDueDate)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.eventName = nil;
    self.managedObjectContext = nil;
    self.meeting = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Lazy Getters

-(NSManagedObjectContext *)managedObjectContext{
    if (_managedObjectContext == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = application.managedObjectContext;
        
    }
    return _managedObjectContext;
}

@end
