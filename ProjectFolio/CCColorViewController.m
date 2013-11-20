//
//  CCColorViewController.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/28/13.
//
//

#import "CCColorViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CCColorViewController ()
@property (weak, nonatomic) IBOutlet UILabel *instructions;
@property (weak, nonatomic) IBOutlet UIView *tintColors;
@property (weak, nonatomic) IBOutlet UIView *backGroundColors;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) UITapGestureRecognizer *taps;
@property (strong, nonatomic) UITapGestureRecognizer *tintTaps;

@end

@implementation CCColorViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	if ([self.colorMode isEqualToString:@"Tint"]) {
        [self setForTint];
    } else {
        [self setForBackground];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors
- (NSUserDefaults *)defaults {
    if (!_defaults) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    
    return _defaults;
}

#pragma mark - Tap Handlers
-(IBAction)tintTapHandler:(UITapGestureRecognizer *)sender{
    CGPoint currentTouch = [sender locationInView:self.backGroundColors];
    int x = currentTouch.x;
    int z = 0;
    if (x > 19 &&  x < 76){
        x = 1;
    } else if ( x > 82 && x < 139 ){
        x = 2;
    } else if ( x > 145 && x < 207) {
        x = 3;
    } else if ( x > 208 && x < 275) {
        x = 4;
    }
    
    z = x - 1;
    UIView *subView = [self.tintColors.subviews objectAtIndex:z];
    UIColor *viewColor = subView.backgroundColor;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    BOOL answer = [viewColor getRed:&red green:&green blue:&blue alpha:&alpha];
    if (answer == YES) {
        [[UIApplication sharedApplication] keyWindow].tintColor = viewColor;
        [self.defaults setFloat:red forKey:kRedTintNameKey];
        [self.defaults setFloat:green forKey:kGreenTintNameKey];
        [self.defaults setFloat:blue forKey:kBlueTintNameKey];
        [self.defaults setFloat:alpha forKey:kTintSaturation];
    }
}

-(IBAction)tapHandler:(UITapGestureRecognizer *)sender{
    CGPoint currentTouch = [sender locationInView:self.backGroundColors];
    int x = currentTouch.x;
    int y = currentTouch.y;
    int z = 0;
    if (x > 10 &&  x < 71){
        x = 1;
    } else if ( x > 78 && x < 139 ){
        x = 2;
    } else if ( x > 146 && x < 207) {
        x = 3;
    } else if ( x > 214 && x < 275) {
        x = 4;
    }
    
    z = x - 1;
    if (y >= 10 &&  y < 71){
        y = 1;
    } else if ( y > 78 && y < 139 ){
        y = 2;
    } else if ( y > 146 && y < 207) {
        y = 3;
    }
    y = y - 1;
    z = z + ( y * 4 );
    if (z < 0 || z > 11) {
        z = 0;
    }
    
    // NSLog(@"x: %d y: %d view pointer: %d", x, y, z);
    
    UIView *subView = [self.backGroundColors.subviews objectAtIndex:z];
    UIColor *viewColor = subView.backgroundColor;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    BOOL answer = [viewColor getRed:&red green:&green blue:&blue alpha:&alpha];
    if (answer == YES) {
        [self.defaults setFloat:red forKey:kRedNameKey];
        [self.defaults setFloat:green forKey:kGreenNameKey];
        [self.defaults setFloat:blue forKey:kBlueNameKey];
        [self.defaults setFloat:alpha forKey:kSaturation];
        NSString *colorChangeNotification = [[NSString alloc] initWithFormat:@"%@", @"BackGroundColorChangeNotification"];
        NSNotification *colorChange = [NSNotification notificationWithName:colorChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:colorChange];
        
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)  {
            [self setDisplayBackGroundColor];
        }
    }
}

#pragma mark - Helpers
- (void)setForTint {
    self.navigationItem.title = @"Application Tint";
    self.instructions.text = @"Tap colored box to set application tint";
    self.backGroundColors.hidden = YES;
    self.tintColors.hidden = NO;
    [self setViewBorders:self.tintColors];
}

- (void)setForBackground {
//    self.taps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
//    [self.taps setNumberOfTapsRequired:2];
//    [self.taps setNumberOfTouchesRequired:1];
    
    self.navigationItem.title = @"Background Color";
    self.instructions.text = @"Tap colored box to set background color of notes";
    self.tintColors.hidden = YES;
    self.backGroundColors.hidden = NO;
    [self setViewBorders:self.backGroundColors];
}

- (void)setViewBorders:(UIView *)colorView {
    colorView.layer.borderWidth = 1.25f;
    colorView.layer.cornerRadius = 5;
    colorView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    for (UIView *view in colorView.subviews) {
        view.layer.borderWidth = 0.5f;
        view.layer.cornerRadius = 3;
        view.layer.borderColor = [[UIColor darkGrayColor]CGColor];
    }
}

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

@end
