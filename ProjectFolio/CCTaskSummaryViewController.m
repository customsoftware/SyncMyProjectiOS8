//
//  CCTaskSummaryViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/8/12.
//
//

#import "CCTaskSummaryViewController.h"

@interface CCTaskSummaryViewController ()
@property (strong, nonatomic) CCChart *chart;

@end

@implementation CCTaskSummaryViewController
@synthesize summaryDelegate = _summaryDelegate;
@synthesize chart = _chart;
@synthesize aProject = _aProject;
@synthesize navBar = _navBar;

-(Project *)getControllingProject{
    return [self.summaryDelegate getControllingProject];
}

-(void)updateViewContents{
    [self.chart refreshDrawing];
}

-(IBAction)doneButton:(UIBarButtonItem *)sender{
    [self.summaryDelegate cancelSummaryChart];
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
    // self.navBar = [[NSString alloc]initWithFormat:@"Task Chart For: %@", self.aProject.projectName ];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.navBar = nil;
    self.aProject = nil;
    self.chart = nil;
    self.summaryDelegate =nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
