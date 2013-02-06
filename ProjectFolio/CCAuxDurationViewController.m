//
//  CCAuxDurationViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import "CCAuxDurationViewController.h"
#define kOnesSpinner      2
#define kTensSpinner      1
#define kHundredsSpinner  0


@interface CCAuxDurationViewController ()
@property (strong, nonatomic) NSArray *hundreds;
@property (strong, nonatomic) NSArray *tens;
@property (strong, nonatomic) NSArray *ones;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@end

@implementation CCAuxDurationViewController

@synthesize durationDelegate = _durationDelegate;
@synthesize countDown = _countDown;
@synthesize hundreds = _hundreds;
@synthesize tens = _tens;
@synthesize ones = _ones;
@synthesize spinnerValue = _spinnerValue;
@synthesize numberFormatter = _numberFormatter;

#pragma mark - IBAction/Delegates
-(IBAction)cancel:(UIBarButtonItem *)sender{
    [self.durationDelegate cancelPopover];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)save:(UIBarButtonItem *)sender{
    [self.durationDelegate savePopoverData];
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 3;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    NSInteger retvalue = 0;
    if (component == kHundredsSpinner) {
        retvalue = [self.hundreds count];
    } else if (component == kTensSpinner) {
        retvalue = [self.tens count];
    } else if (component == kOnesSpinner ){
       retvalue = [self.ones count];
    }
    return retvalue;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSString *retvalue = nil;
    if (component == kHundredsSpinner) {
        retvalue = [self.hundreds objectAtIndex:row];
    } else if (component == kTensSpinner) {
        retvalue = [self.tens objectAtIndex:row];
    } else if ( component == kOnesSpinner ){
        retvalue = [self.ones objectAtIndex:row];
    }
    return retvalue;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    int value;
    NSInteger hundredsRow = [self.countDown selectedRowInComponent:kHundredsSpinner];
    NSInteger tensRow = [self.countDown selectedRowInComponent:kTensSpinner];
    NSInteger onesRow = [self.countDown selectedRowInComponent:kOnesSpinner];
    
    value = [[self.numberFormatter numberFromString:[self.hundreds objectAtIndex:hundredsRow]] integerValue];
    value = value + [[self.numberFormatter numberFromString:[self.tens objectAtIndex:tensRow]] integerValue];
    value = value + [[self.numberFormatter numberFromString:[self.ones objectAtIndex:onesRow]] integerValue];
    
    self.spinnerValue = [NSNumber numberWithInt:value];
    self.navigationItem.title = [[NSString alloc] initWithFormat:@"Interval: %d", value];
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
    self.hundreds = [[NSArray alloc] initWithObjects:@"000", @"100", @"200", @"300", @"400", @"500", @"600", nil];
    self.tens = [[NSArray alloc] initWithObjects:@"00", @"10", @"20", @"30", @"40", @"50", @"60", @"70", @"80", @"90", nil];
    self.ones = [[NSArray alloc] initWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    if ([self.spinnerValue integerValue] > 0) {
        int hundreds = round([self.spinnerValue integerValue]/100)*100;
        int tens = (round([self.spinnerValue integerValue]/10)*10) - hundreds;
        int ones = [self.spinnerValue integerValue] - hundreds - tens;
        
        NSInteger spinnerPointer = [self.hundreds indexOfObject:[[NSString alloc] initWithFormat:@"%d", hundreds]];
        if (spinnerPointer >= 0 && spinnerPointer < [self.hundreds count]) {
            [self.countDown selectRow:spinnerPointer inComponent:kHundredsSpinner animated:NO];
        }
        spinnerPointer = [self.tens indexOfObject:[[NSString alloc] initWithFormat:@"%d", tens]];
        if (spinnerPointer >= 0 && spinnerPointer < [self.tens count]) {
            [self.countDown selectRow:spinnerPointer inComponent:kTensSpinner animated:NO];
        }
        spinnerPointer = [self.ones indexOfObject:[[NSString alloc] initWithFormat:@"%d", ones]];
        if (spinnerPointer >= 0 && spinnerPointer < [self.ones count]) {
            [self.countDown selectRow:spinnerPointer inComponent:kOnesSpinner animated:NO];
        }
        self.navigationItem.title = [[NSString alloc] initWithFormat:@"Interval: %d", [self.spinnerValue integerValue]];
    } else {
        [self.countDown selectRow:0 inComponent:kHundredsSpinner animated:NO];
        [self.countDown selectRow:0 inComponent:kTensSpinner animated:NO];
        [self.countDown selectRow:0 inComponent:kOnesSpinner animated:NO];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	// Do any additional setup after loading the view.
    self.countDown = nil;
    self.durationDelegate = nil;
    self.hundreds = nil;
    self.tens = nil;
    self.ones = nil;
    self.spinnerValue = nil;
    self.numberFormatter = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy Getters

-(NSNumberFormatter *)numberFormatter{
    if (_numberFormatter == nil) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setFormatterBehavior:NSNumberFormatterBehaviorDefault];
    }
    
    return _numberFormatter;
}

@end
