//
//  CCDateSetterViewController.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCDateSetterViewController.h"
#import "CCSettingsControl.h"

#define START_INDEX [NSIndexPath indexPathForRow:0 inSection:0]
#define END_INDEX [NSIndexPath indexPathForRow:1 inSection:0]
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]
#define runningOnIPad    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

@interface CCDateSetterViewController ()

@property (strong, nonatomic) CCAuxDurationViewController *durationController;
@property (strong, nonatomic) CCCategoryTaskViewController *categoryController;
@property (strong, nonatomic) UISwipeGestureRecognizer *hideSwipe;
@property (weak, nonatomic) IBOutlet UILabel *costBudgetLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateBudgetLabel;
@property (weak, nonatomic) IBOutlet UILabel *hourBudgetLabel;
@property (weak, nonatomic) IBOutlet UITextField *hourBudgetField;
@property (weak, nonatomic) IBOutlet UIButton *projectCategory;
@property (weak, nonatomic) IBOutlet UIButton *completionDate;
@property (weak, nonatomic) IBOutlet UIButton *startDate;
@property (weak, nonatomic) IBOutlet UIButton *customerName;
@property (weak, nonatomic) IBOutlet UITextView *helpText;
@property (strong, nonatomic) CCSettingsControl *settings;
@property (weak, nonatomic) IBOutlet UIButton *canWeFinish;

- (IBAction)runCanDoAnalysis:(UIButton *)sender;
- (IBAction)runProjectClonePopover:(UIButton *)sender;
- (void)releaseForm:(UIButton *)sender;
- (IBAction)changedBudget:(UITextField *)sender;
- (IBAction)changeProjectCategory:(UIButton *)sender;
- (IBAction)setExpectedCompletionDate:(UIButton *)sender;
- (IBAction)setProjectStartDate:(UIButton *)sender;
- (IBAction)setProjectCustomer:(UIButton *)sender;

@end

@implementation CCDateSetterViewController

#pragma mark - Popover Controls
- (IBAction)runCanDoAnalysis:(UIButton *)sender
{
    [CCCanIDoIt runAnalysisForProject:self.project];
}

- (IBAction)runProjectClonePopover:(UIButton *)sender
{
    CCAuxTaskCloneViewController *cloner =  [self.storyboard instantiateViewControllerWithIdentifier:@"projectCloneControl"];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cloner];
    cloner.selectedProject = self.project;
    if (runningOnIPad) {
        cloner.preferredContentSize = CGSizeMake(400, 300);
        self.popControll = [[UIPopoverController alloc] initWithContentViewController:nc];
        [self.popControll presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController pushViewController:cloner animated:YES];
    }
}

- (void)releaseForm:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changedBudget:(UITextField *)sender {
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    self.project.hourBudget = [numFormatter numberFromString:sender.text];
    [self updateBillableValues];
}

- (IBAction)changeProjectCategory:(UIButton *)sender {
    [self callCategoryController];
}

- (IBAction)setExpectedCompletionDate:(UIButton *)sender {
    self.dateController =  [self.storyboard instantiateViewControllerWithIdentifier:@"projectDateSetter"];
    self.dateController.delegate = self;
    self.dateController.dateValue = self.project.dateFinish;
    self.dateController.minimumDate = self.project.dateStart;
    self.dateController.maximumDate = nil;
    self.dateController.barCaption = @"End Date";
    if (runningOnIPad) {
        self.dateController.preferredContentSize = self.preferredContentSize;
        self.popControll = [[UIPopoverController alloc] initWithContentViewController:self.dateController];
        [self.popControll presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController pushViewController:self.dateController animated:YES];
    }
}

- (IBAction)setProjectStartDate:(UIButton *)sender {
    self.dateController =  [self.storyboard instantiateViewControllerWithIdentifier:@"projectDateSetter"];
    self.dateController.delegate = self;
    self.dateController.dateValue = self.project.dateStart;
    self.dateController.minimumDate = nil;
    self.dateController.maximumDate = self.project.dateFinish;
    self.dateController.barCaption = @"Start Date";
    if (runningOnIPad) {
        self.dateController.preferredContentSize = self.preferredContentSize;
        self.popControll = [[UIPopoverController alloc] initWithContentViewController:self.dateController];
        [self.popControll presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController pushViewController:self.dateController animated:YES];
    }
}

- (IBAction)setProjectCustomer:(UIButton *)sender {
    [self callOwnerController];
}

-(IBAction)completeProject:(UISwitch *)sender{
    self.project.complete = [NSNumber numberWithBool:[sender isOn]];
    [self.view endEditing:YES];
}

-(IBAction)projectActive:(UISwitch *)sender{
    self.project.active = [NSNumber numberWithBool:[sender isOn]];
    [self.view endEditing:YES];
}

-(IBAction)billableProject:(UISwitch *)sender{
    self.project.billable = [NSNumber numberWithBool:[sender isOn]];
    if ([sender isOn] && [self.project.hourlyRate floatValue] == 0 && [self.project.costBudget floatValue] == 0 && [self.project.hourBudget floatValue] == 0 ){
        UIAlertView * alert = [[UIAlertView alloc]
                               initWithTitle:@"Billing Configuration Alert" message:@"You've declared the project to be billable. Remember to set the Hourly Rate, Cost Budget and Duration Values." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self setVisibilityOfBillableControls:[sender isOn]];
    [self.view endEditing:YES];
}

-(IBAction)name:(UITextField *)sender{
    self.project.projectName = sender.text;
}

-(IBAction)hourlyRate:(UITextField *)sender{
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    self.project.hourlyRate = [numFormatter numberFromString:sender.text];
    [self updateBillableValues];
}

-(IBAction)projectCostBudget:(UITextField *)sender{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSDecimalNumber *targetValue = [[NSDecimalNumber alloc] initWithFloat:[[formatter numberFromString:sender.text] floatValue]];
    self.project.costBudget = targetValue;
    [self updateBillableValues];
}

-(void)callOwnerController{
    self.ownerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.ownerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.ownerController.peoplePickerDelegate = self;
    self.ownerController.preferredContentSize = self.preferredContentSize;
    [self presentViewController:self.ownerController animated:YES completion:nil];
}

-(void)callCategoryController{
    self.categoryController.categoryDelegate = self;
    if (runningOnIPad) {
        self.categoryController.preferredContentSize = CGSizeMake(320, 300);
        self.popControll = [[UIPopoverController alloc] initWithContentViewController:self.categoryController];
        [self.popControll presentPopoverFromRect:self.projectCategory.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController pushViewController:self.categoryController animated:YES];
    }
}

#pragma mark - Addressbook delegates
-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.project.assignedTo = nil;
    [self.customerName setTitle:@"Project Customer" forState:UIControlStateNormal];
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    [self displayPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

-(void)displayPerson:(ABRecordRef)person{
    NSString *name =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.project.assignedToFirst = name;
    self.project.assignedToLast = lastName;
    self.project.assignedTo = [[NSString alloc] initWithFormat:@"%@ %@", name, lastName];
    NSString *projectCustomer = [NSString stringWithFormat:@"Project Customer: %@", self.project.assignedTo];
    [self.customerName setTitle:projectCustomer forState:UIControlStateNormal];
}

#pragma mark - Delegate
-(void)saveDateValue:(NSDate *)dateValue{
    if ([self.dateController.barCaption isEqualToString:@"Start Date"]) {
        self.project.dateStart = dateValue;
    } else {
        self.project.dateFinish = dateValue;
    }
    [self setViewControlValues];
}

-(void)cancelPopover{
    self.durationController.spinnerValue = nil;
    self.project.hourBudget = nil;
}

-(void)savePopoverData{
    [self setViewControlValues];
}

-(Priority *)getCurrentCategory{
    return self.project.projectPriority;
}

-(void)saveSelectedCategory:(Priority *)newCategory{
    self.project.projectPriority = newCategory;
    [self setViewControlValues];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            self.project.hourBudget = [NSNumber numberWithInt:0];
            self.project.hourlyRate = [NSNumber numberWithInt:0];
            self.project.costBudget = [[NSDecimalNumber alloc] initWithFloat:[[formatter numberFromString:0] floatValue]];
            [self setViewControlValues];
        }
    }
}

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setViewControlValues) name:kiCloudSyncNotification object:nil];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    if (runningOnIPad) {
        UISwipeGestureRecognizer *hideSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(releaseForm:)];
        [hideSwipe setDirection:UISwipeGestureRecognizerDirectionUp];
        [self.view addGestureRecognizer:hideSwipe];
    }
    
    UITapGestureRecognizer *resetTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetBudget)];
    [resetTap setNumberOfTapsRequired:2];
    [resetTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:resetTap];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ProjectDetails" ofType:@"txt"];
    
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    self.helpText.text = content;
    
    NSString *colorChangeNotification = @"BackGroundColorChangeNotification";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDisplayBackGroundColor) name:colorChangeNotification object:nil];
    [self setDisplayBackGroundColor];
    
    if (!runningOnIPad) {
        UITapGestureRecognizer *singleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTaps)];
        [singleTapper setNumberOfTapsRequired:1];
        [singleTapper setNumberOfTouchesRequired:1];
        [self.view addGestureRecognizer:singleTapper];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self setViewControlValues];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.project) {
        [self.project.managedObjectContext save:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Delegates
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self setViewControlValues];
}

#pragma mark - Helpers
- (void)handleTaps {
    [self.view endEditing:YES];
}

- (void)resetBudget {
    if ([self.settings isTimeAuthorized] || [self.settings isExpenseAuthorized]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Reseting Budget" message:@"Are you certain you want to reset the budget entries?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alert.tag = 2;
        [alert show];
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

- (void)updateBillableValues {
    // If we have all three values: duration, rate and cost budget, nothing will be done
    // If we have Rate and Cost, we'll compute hours
    // If we have Rate and hours, we'll compute cost
    // If we have Cost and Hours, we'll compute rate
    float rate = [self.project.hourlyRate floatValue];
    float cost = [self.project.costBudget floatValue];
    float hours = [self.project.hourBudget floatValue];
    
    if ( rate > 0 && cost > 0 && hours > 0 ) {
        // We don't need to do anything
    } else if ( rate > 0 && cost > 0 ){
        // We compute hours
        hours = cost / rate;
        hours = roundf(hours);
        self.project.hourBudget = [NSNumber numberWithFloat:hours];
        self.hourBudgetField.text = [NSString stringWithFormat:@"%.2f", hours];
        
    } else if ( rate > 0 && hours > 0 ){
        // We compute cost
        cost = rate * hours;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSDecimalNumber *targetValue = [[NSDecimalNumber alloc] initWithFloat:cost];
        self.project.costBudget = targetValue;
        self.projectCostBudget.text = [NSString stringWithFormat:@"%.2f", cost];
        
    } else if ( hours > 0 && cost > 0 ){
        // We compute rate
        rate = cost/hours;
        self.project.hourlyRate = [NSNumber numberWithFloat:rate];
        self.hourlyRateField.text = [NSString stringWithFormat:@"%.2f", rate];
    }
}

- (void)setViewControlValues {
    NSString *projectCustomer = nil;
    if (self.project.assignedTo) {
        projectCustomer = [NSString stringWithFormat:@"Project Customer: %@", self.project.assignedTo];
    } else { projectCustomer = [NSString stringWithFormat:@"Project Customer"]; }
    [self.customerName setTitle:projectCustomer forState:UIControlStateNormal];
    
    NSString * startDate = nil;
    if (self.project.dateStart) {
        startDate = [NSString stringWithFormat:@"Start On: %@", [self.dateFormatter stringFromDate:self.project.dateStart]];
    } else { startDate = @"Start Date"; }
    [self.startDate setTitle:startDate forState:UIControlStateNormal];
    
    NSString * stopDate = nil;
    if (self.project.dateFinish) {
        stopDate = [NSString stringWithFormat:@"Due by: %@", [self.dateFormatter stringFromDate:self.project.dateFinish]];
    } else { stopDate = @"Scheduled Completion Date"; }
    [self.completionDate setTitle:stopDate forState:UIControlStateNormal];
    
    NSString *category = nil;
    if (self.project.projectPriority.priority) {
        category = [NSString stringWithFormat:@"Category: %@", self.project.projectPriority.priority];
    } else { category = @"Project Category"; }
    [self.projectCategory setTitle:category forState:UIControlStateNormal];
    
    self.projectName.text = self.project.projectName;
    NSString *hourlyRate = nil;
    if (self.project.hourlyRate) {
        hourlyRate = [NSString stringWithFormat:@"%@", self.project.hourlyRate];
    } else { hourlyRate = @""; }
    self.hourlyRateField.text = hourlyRate;
    
    NSString *hourBudget = nil;
    if (self.project.hourBudget) {
        hourBudget = [NSString stringWithFormat:@"%@", self.project.hourBudget];
    } else { hourBudget = @""; }
    self.hourBudgetField.text = hourBudget;
    self.hourBudgetField.enabled = [self.settings isTimeAuthorized];
    self.canWeFinish.enabled = [self.settings isTimeAuthorized];
    self.startDate.enabled = [self.settings isTimeAuthorized];
    self.completionDate.enabled = [self.settings isTimeAuthorized];
    self.billableSwitch.enabled = [self.settings isExpenseAuthorized];
    self.hourlyRateField.enabled = [self.settings isExpenseAuthorized];
    self.projectCostBudget.enabled = [self.settings isExpenseAuthorized];
    
    self.projectCostBudget.text = [self.project.costBudget stringValue];
    [self.activeSwitch setOn:[self.project.active boolValue]];
    [self.completeSwitch setOn:[self.project.complete boolValue]];
    [self.billableSwitch setOn:[self.project.billable boolValue]];
    [self setVisibilityOfBillableControls:[self.project.billable boolValue]];
    [self updateBillableValues];
}

- (void)setVisibilityOfBillableControls:(BOOL)enabled {
    self.hourlyRateField.hidden = !enabled;
    self.projectCostBudget.hidden = !enabled;
    self.rateBudgetLabel.hidden = !enabled;
    self.costBudgetLabel.hidden = !enabled;
}

#pragma mark - Accessors
-(CCSettingsControl *)settings{
    if (_settings == nil) {
        _settings = [[CCSettingsControl alloc] init];
    }
    return _settings;
}

-(ABPeoplePickerNavigationController *)ownerController{
    if (_ownerController == nil) {
        _ownerController = [[ABPeoplePickerNavigationController alloc] init];
    }
    return _ownerController;
}

-(CCAuxDurationViewController *)durationController{
    if (_durationController == nil) {
        _durationController = [self.storyboard instantiateViewControllerWithIdentifier:@"durationViewController"];
    }
    return _durationController;
}

-(CCCategoryTaskViewController *)categoryController{
    if (_categoryController == nil) {
        _categoryController = [self.storyboard instantiateViewControllerWithIdentifier:@"categoryViewController"];
    }
    return _categoryController;
}

@end
