//
//  CCNewProjectViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/17/13.
//
//

#import "CCNewProjectViewController.h"

@interface CCNewProjectViewController ()
- (IBAction)saveProjectName:(UIBarButtonItem *)sender;
- (IBAction)cancelNewProject:(UIBarButtonItem *)sender;
- (IBAction)projectName:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation CCNewProjectViewController

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
    [self setFontForDisplay];
    [self setDisplayBackGroundColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveProjectName:(UIBarButtonItem *)sender {
    [self.popoverDelegate savePopoverData];
}

- (IBAction)cancelNewProject:(UIBarButtonItem *)sender {
    [self.popoverDelegate cancelPopover];
}

- (IBAction)projectName:(UITextField *)sender {
    self.saveButton.enabled = YES;
}

#pragma mark - Helpers
-(void)setFontForDisplay{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    NSString *nullString = [[NSString alloc] initWithFormat:@"%@", nil];
    if ([fontFamily isEqualToString:nullString]) {
        fontFamily = @"Optima";
    }
    CGFloat fontSize = [defaults integerForKey:kFontSize];
    if (fontSize < 16) {
        fontSize = 16;
    }
    UIFont *displayFont = [UIFont fontWithName:fontFamily size:fontSize];
    self.projectName.font = displayFont;
}

-(void)setDisplayBackGroundColor{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat alpha = [defaults floatForKey:kSaturation];
    CGFloat red = [defaults floatForKey:kRedNameKey];
    CGFloat blue = [defaults floatForKey:kBlueNameKey];
    CGFloat green = [defaults floatForKey:kGreenNameKey];
    UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    self.view.backgroundColor = newColor;
}
@end
