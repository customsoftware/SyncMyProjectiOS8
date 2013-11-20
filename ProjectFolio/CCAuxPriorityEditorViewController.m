//
//  CCAuxPriorityEditorViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import "CCAuxPriorityEditorViewController.h"

@interface CCAuxPriorityEditorViewController ()
-(IBAction)updatePriority:(UITextField * )sender;
@property (weak, nonatomic) IBOutlet UIView *colorPad;
@property (weak, nonatomic) IBOutlet UITextField *textField;


@end

@implementation CCAuxPriorityEditorViewController

-(IBAction)updatePriority:(UITextField *)sender{
     [self.priorityDelegate saveUpdatedDetail:sender.text];
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
    self.priorityText.backgroundColor = [self convertNSStringToColor:[self.priorityDelegate getPriorityColor]];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.priorityDelegate saveUpdatedDetail:self.priorityText.text];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.colorPad.layer.borderWidth = 1.25f;
    self.colorPad.layer.cornerRadius = 5;
    self.colorPad.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    for (UIView *view in self.colorPad.subviews) {
        view.layer.borderWidth = 1.25f;
        view.layer.cornerRadius = 3;
        view.layer.borderColor = [[UIColor darkGrayColor]CGColor];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
-(IBAction)tapHandler:(UITapGestureRecognizer *)sender{
    CGPoint currentTouch = [sender locationInView:self.colorPad];
    int x = currentTouch.x;
    int y = currentTouch.y;
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
    if (y >= 20 &&  y < 76){
        y = 1;
    } else if ( y > 82 && y < 139 ){
        y = 2;
    } else if ( y > 145 && y < 207) {
        y = 3;
    }
    y = y - 1;
    z = z + ( y * 4 );
    if (z < 0 || z > 11) {
        z = 0;
    }
    
//    NSLog(@"x: %d y: %d view pointer: %d", x, y, z);
    
    UIView *subView = [self.colorPad.subviews objectAtIndex:z];
    UIColor *viewColor = subView.backgroundColor;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    BOOL answer = [viewColor getRed:&red green:&green blue:&blue alpha:&alpha];
    if (answer == YES) {
        self.textField.backgroundColor = viewColor;
        [self.priorityDelegate saveUpdatedColor:[self convertUIColorToString:viewColor]];
    }
}

#pragma mark - Delegates
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textField resignFirstResponder];
}

#pragma mark - Helpers
- (NSString *)convertUIColorToString:(UIColor *)color
{
    NSString *convertedColor = nil;
    CGFloat red, green, blue, alpha;
    int r, g, b;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    r = (int)255.0*red;
    g = (int)255.0*green;
    b = (int)255.0*blue;
    convertedColor =  [NSString stringWithFormat:@"%02x%02x%02x",r,g,b];
    return convertedColor;
}

- (UIColor *)convertNSStringToColor:(NSString *)hexString
{
    UIColor *textColor = nil;
    if (hexString) {
        unsigned rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner scanHexInt:&rgbValue];
        int r = (rgbValue >> 16) & 0xFF;
        int g = (rgbValue >> 8) & 0xFF;
        int b = (rgbValue) & 0xFF;
        textColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    } else {
        textColor = [UIColor whiteColor];
    }
    return textColor;
}

@end
