//
//  CCUpgradesViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 8/3/13.
//
//

#import "CCUpgradesViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CCUpgradesViewController ()
@property (weak, nonatomic) IBOutlet UIButton *iCloudButton;
- (IBAction)iCloudSync:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UITextView *iCloudText;

@end

@implementation CCUpgradesViewController

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
    self.iCloudText.layer.cornerRadius = 5;
    self.iCloudText.layer.borderColor = [[UIColor darkGrayColor]CGColor];
    self.iCloudText.layer.borderWidth = 2;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iCloudSync:(UIButton *)sender {
}
@end
