//
//  CCDeliverableDetailsViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import "CCDeliverableDetailsViewController.h"
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]

@interface CCDeliverableDetailsViewController ()

@end

@implementation CCDeliverableDetailsViewController
@synthesize expense = _expense;
@synthesize payee = _payee;
@synthesize expensed = _expensed;
@synthesize amountPaid = _amountPaid;
@synthesize notes = _notes;
@synthesize itemPurchased = _itemPurchased;
@synthesize datePicker = _datePicker;

#pragma mark - IBAction
-(IBAction)expensed:(UISwitch *)sender{
    self.expense.expensed = ([sender isOn]) ? SWITCH_ON:SWITCH_OFF;
    if ([sender isOn]) {
        self.expense.dateExpensed = [NSDate date];
    } else {
        self.expense.dateExpensed = nil;
    }
    [self.view endEditing:YES];
}

-(IBAction)amountPaid:(UITextField *)sender{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    self.expense.amount = [formatter numberFromString:sender.text];
    [self.view endEditing:YES];
}

-(IBAction)payee:(UITextField *)sender{
    self.expense.paidTo = sender.text;
    [self.view endEditing:YES];
}

-(IBAction)itemPurchased:(UITextField *)sender{
    self.expense.pmtDescription = sender.text;
    [self.view endEditing:YES];
}

-(IBAction)datePicker:(UIDatePicker *)sender{
    self.expense.datePaid = sender.date;
}

#pragma mark - Delegates
-(void)saveDateValue:(NSDate *)dateValue{
    [self.expense.managedObjectContext save:nil];
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
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Deliverable Details";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadViewProperties) name:kiCloudSyncNotification object:nil];

}

-(void)viewWillAppear:(BOOL)animated{
    [self reloadViewProperties];
    // [self.deliverableParameters reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.expense.notes = self.notes.text;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)reloadViewProperties {
    self.payee.text = self.expense.paidTo;
    self.notes.text = self.expense.notes;
    self.itemPurchased.text = self.expense.pmtDescription;
    self.amountPaid.text = [self.expense.amount stringValue];
    BOOL activeVal = [self.expense.expensed boolValue];
    [self.expensed setOn:activeVal];
    if (self.expense.datePaid == nil) {
        self.expense.datePaid = [NSDate date];
    }
    self.datePicker.date = self.expense.datePaid;
}

#pragma mark - Table View Data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"taskDetails";
    UITableViewCell *returnCell= [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (returnCell == nil) {
            returnCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
    return returnCell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
}


@end
