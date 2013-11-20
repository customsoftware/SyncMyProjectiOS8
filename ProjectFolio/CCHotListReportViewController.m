//
//  CCHotListReportViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import "CCHotListReportViewController.h"

@interface CCHotListReportViewController ()

@end

@implementation CCHotListReportViewController
#pragma mark - API
-(NSString *)getTaskListReportForProject:(Project *)project{
    return @"Not finished yet";
}

-(NSString *)getHotListReportForStatus:(NSInteger)pointer{
    return @"Not finished yet";
}

-(NSString *)getLocationOfPDFTaskListReportForProject:(Project *)project{
    return @"Not finished yet";
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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
