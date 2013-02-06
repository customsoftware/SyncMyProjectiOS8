//
//  CCAuxPriorityEditorViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import "CCAuxPriorityEditorViewController.h"

@interface CCAuxPriorityEditorViewController ()

@end

@implementation CCAuxPriorityEditorViewController
@synthesize priorityDelegate = _priorityDelegate;

-(IBAction)updatePriority:(UITextField *)sender{
    // [self.priorityDelegate saveUpdatedDetail:sender.text];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.priorityText.text = [self.priorityDelegate getDetailValue];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.priorityDelegate saveUpdatedDetail:self.priorityText.text];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)viewDidUnload{
    [super viewDidUnload];
    self.priorityDelegate = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
