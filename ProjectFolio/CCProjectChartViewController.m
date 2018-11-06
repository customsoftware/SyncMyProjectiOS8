//
//  CCProjectChartViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 8/22/12.
//
//

#import "CCProjectChartViewController.h"

@interface CCProjectChartViewController ()

@end

@implementation CCProjectChartViewController
@synthesize delegate = _delegate;
@synthesize chartView = _chartView;

-(UIInterfaceOrientation)getDeviceOrientation{
    return self.interfaceOrientation;
}

-(IBAction)closeChart:(id)sender{
    [self.delegate dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Life Cycle
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
    self.chartView.barDelegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.delegate = nil;
    self.chartView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
