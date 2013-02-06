//
//  CCAuxDateViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/1/12.
//
//

#import "CCAuxDateViewController.h"

@interface CCAuxDateViewController ()

@end

@implementation CCAuxDateViewController
@synthesize barCaption = _barCaption;
@synthesize dateValue = _dateValue;
@synthesize projectDate = _projectDate;
@synthesize minimumDate = _minimumDate;
@synthesize maximumDate = _maximumDate;

-(IBAction)newDate:(UIDatePicker *)sender{
    [self.delegate saveDateValue:sender.date];
}

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
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.title = self.barCaption;
    if (self.dateValue ==  nil) {
        self.dateValue = [NSDate date ];
    }
    self.projectDate.date = self.dateValue;
    self.projectDate.maximumDate = self.maximumDate;
    self.projectDate.minimumDate = self.minimumDate;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.projectDate = nil;
    self.dateValue = nil;
    self.barCaption = nil;
    self.minimumDate = nil;
    self.maximumDate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
