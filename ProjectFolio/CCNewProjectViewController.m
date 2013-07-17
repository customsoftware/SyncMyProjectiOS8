//
//  CCNewProjectViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 4/5/13.
//
//

#import "CCNewProjectViewController.h"
#define kBlueNameKey @"bluebalance"
#define kRedNameKey @"redbalance"
#define kGreenNameKey @"greenbalance"
#define kSaturation @"saturation"
#define kFontNameKey @"font"
#define kFontSize @"fontSize"

@interface CCNewProjectViewController ()

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
    [self setDisplayBackGroundColor];
    [self setFontForDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Configure view
-(void)setDisplayBackGroundColor{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat alpha = [defaults floatForKey:kSaturation];
    CGFloat red = [defaults floatForKey:kRedNameKey];
    CGFloat blue = [defaults floatForKey:kBlueNameKey];
    CGFloat green = [defaults floatForKey:kGreenNameKey];
    UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    //self.projectNotes.backgroundColor = newColor;
    self.view.backgroundColor = newColor;
}

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
    self.label.font = displayFont;
}

#pragma mark - IBActions
- (IBAction)saveData:(UIBarButtonItem *)sender {
    [self.view endEditing:YES];
    [self.popoverDelegate savePopoverData];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self.view endEditing:YES];
    [self.popoverDelegate cancelPopover];
}

- (IBAction)projectName:(UITextField *)sender {
    
}

- (void)viewDidUnload {
    [self setLabel:nil];
    [super viewDidUnload];
}
@end
