//
//  CCDateSetterViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCDateSetterViewController.h"

#define START_INDEX [NSIndexPath indexPathForRow:0 inSection:0]
#define END_INDEX [NSIndexPath indexPathForRow:1 inSection:0]
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]

@interface CCDateSetterViewController ()

@property (strong, nonatomic) CCAuxDurationViewController *durationController;
@property (strong, nonatomic) CCCategoryTaskViewController *categoryController;

@end

@implementation CCDateSetterViewController

#pragma mark - Popover Controls
- (void)runCanDoAnalysis
{
    [CCCanIDoIt runAnalysisForProject:self.project];
}

- (void)runProjectClonePopover
{
    [self performSegueWithIdentifier:@"projectClone" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    UIViewController *destinationView = [segue destinationViewController];
    if ([[segue identifier] isEqualToString:@"projectClone"]) {
        CCAuxTaskCloneViewController *taskCloneController = (CCAuxTaskCloneViewController *)destinationView;
        taskCloneController.selectedProject = self.project;
    }
    destinationView.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
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
    if ([sender isOn] && [self.project.hourlyRate floatValue] == 0 ){
        UIAlertView * alert = [[UIAlertView alloc]
                               initWithTitle:@"Data Inconsistency Warning" message:@"You've declared the project to be billable without setting a billable rate" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self.view endEditing:YES];
}

-(IBAction)name:(UITextField *)sender{
    self.project.projectName = sender.text;
}

-(IBAction)hourlyRate:(UITextField *)sender{
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    self.project.hourlyRate = [numFormatter numberFromString:sender.text];
}

-(IBAction)projectCostBudget:(UITextField *)sender{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSDecimalNumber *targetValue = [[NSDecimalNumber alloc] initWithFloat:[[formatter numberFromString:sender.text] floatValue]];
    self.project.costBudget = targetValue;
}

-(void)callOwnerController{
    self.ownerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.ownerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.ownerController.peoplePickerDelegate = self;
    self.ownerController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    [self presentViewController:self.ownerController animated:YES completion:nil];
}

-(void)callIntervalController{
    self.durationController.durationDelegate = self;
    self.durationController.spinnerValue = self.project.hourBudget;
    self.durationController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    [self.navigationController pushViewController:self.durationController animated:YES];
}

-(void)callCategoryController{
    self.categoryController.categoryDelegate = self;
    self.categoryController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    [self.navigationController pushViewController:self.categoryController animated:YES];
}

#pragma mark - Addressbook delegates
-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.project.assignedTo = nil;
    [self.settingsController reloadData];
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
    [self.settingsController reloadData];
}
#pragma mark - Delegate
-(void)saveDateValue:(NSDate *)dateValue{
    if ([self.dateController.barCaption isEqualToString:@"Start Date"]) {
        self.project.dateStart = dateValue;
    } else {
        self.project.dateFinish = dateValue;
    }
}

-(void)cancelPopover{
    self.durationController.spinnerValue = nil;
    self.project.hourBudget = nil;
}

-(void)savePopoverData{
    self.project.hourBudget = self.durationController.spinnerValue;
}

-(Priority *)getCurrentCategory{
    return self.project.projectPriority;
}

-(void)saveSelectedCategory:(Priority *)newCategory{
    // Need to add code when you can attach priorities to a project
    self.project.projectPriority = newCategory;
}


#pragma mark - Table View Procedures
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < 2) {
        self.dateController =  [self.storyboard instantiateViewControllerWithIdentifier:@"projectDateSetter"];
        self.dateController.delegate = self;
        if (indexPath.row == 0) {
            self.dateController.dateValue = self.project.dateStart;
            self.dateController.minimumDate = nil;
            self.dateController.maximumDate = nil;
            self.dateController.barCaption = @"Start Date";
        } else {
            self.dateController.dateValue = self.project.dateFinish;
            self.dateController.minimumDate = self.project.dateStart;
            self.dateController.maximumDate = nil;
            self.dateController.barCaption = @"End Date";
        }
        self.dateController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
        [self.navigationController pushViewController:self.dateController animated:YES];
    } else if (indexPath.row == 2 ){
        [self callIntervalController];
    } else if (indexPath.row == 3 ){
        [self callOwnerController];
    } else if (indexPath.row == 4 ){
        [self callCategoryController];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    static NSString *startCellID = @"startCell";
    static NSString *endCellID = @"endCell";
    static NSString *ownerCellID = @"ownerCell";
    static NSString *durationCellID = @"durationCell";
    static NSString *priorityCellID = @"priorityCell";
    NSUInteger row = [indexPath row];
    if (row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:startCellID];            
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:startCellID];
        }
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@", 
                                     [self.dateFormatter stringFromDate:self.project.dateStart]];
    } else if (row == 1 ){
        cell = [tableView dequeueReusableCellWithIdentifier:endCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:endCellID];
        }
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@",
                                     [self.dateFormatter stringFromDate:self.project.dateFinish]];
    } else if (row == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:durationCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:durationCellID];
        }
        
        // Need to set this value....
        int hourBudget = [self.project.hourBudget integerValue];
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%d hours", hourBudget];
        
    } else if (row == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:ownerCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:ownerCellID];
        }
        if (self.project.dueTo == nil) {
            cell.detailTextLabel.text = @"Self";
        } else {
            cell.detailTextLabel.text = self.project.dueTo;
        }
    } else if (row == 4) {
        cell = [tableView dequeueReusableCellWithIdentifier:priorityCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:priorityCellID];
        }
        if (self.project.projectPriority == nil) {
            cell.detailTextLabel.text = @"None selected";
        } else {
            cell.detailTextLabel.text = self.project.projectPriority.priority;
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger result = 5;
    return result;
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
    // Do any additional setup after loading the view from its nib.
    self.settingsController.delegate = self;
    self.settingsController.dataSource = self;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:2];
    UIBarButtonItem *cloneButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"196-radiation.png"] style:UIBarButtonItemStylePlain target:self action:@selector(runCanDoAnalysis)];
    [buttons addObject:cloneButton];
    UIBarButtonItem *canDoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"117-todo.png"] style:UIBarButtonItemStylePlain target:self action:@selector(runProjectClonePopover)];
    [buttons addObject:canDoButton];
    UIToolbar *tools = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 70, 45)];
    [tools setItems:buttons animated:NO];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        tools.barStyle = UIBarStyleBlackTranslucent;
    }
    UIBarButtonItem *twoButtons = [[UIBarButtonItem alloc] initWithCustomView:tools];
    self.navigationItem.rightBarButtonItem = twoButtons;
}

-(void)viewWillAppear:(BOOL)animated{
    [self setViewControlValues];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.project.managedObjectContext save:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Helpers
- (void)setViewControlValues {
    [self.settingsController reloadData];
    self.projectName.text = self.project.projectName;
    self.hourlyRateField.text = [[NSString alloc] initWithFormat:@"%@", self.project.hourlyRate];
    self.projectCostBudget.text = [self.project.costBudget stringValue];
    BOOL activeVal = [self.project.active boolValue];
    [self.activeSwitch setOn:activeVal];
    activeVal = [self.project.complete boolValue];
    [self.completeSwitch setOn:activeVal];
    activeVal = [self.project.billable boolValue];
    [self.billableSwitch setOn:activeVal];
}

#pragma mark - Accessors
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
