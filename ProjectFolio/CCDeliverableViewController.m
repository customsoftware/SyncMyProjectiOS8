//
//  CCDeliverableViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import "CCDeliverableViewController.h"
#define DELIVER_COMPLETE [[NSNumber alloc] initWithInt:1]
#define DELIVER_ACTIVE [[NSNumber alloc] initWithInt:0]

@interface CCDeliverableViewController ()
@property (strong, nonatomic) CCExpenseReporterViewController *expenseCalculator;
@property (strong, nonatomic) CCEmailer *emailer;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) NSIndexPath *theIndex;
@property NSInteger lastSelected;
@property BOOL  isNew;
@property (strong, nonatomic) NSPredicate *billedPredicate;
@property (strong, nonatomic) NSPredicate *unbilledPredicate;
@property (strong, nonatomic) NSPredicate *allPredicate;
@end

@implementation CCDeliverableViewController

@synthesize project = _project;
@synthesize selectedIndexPath = _selectedIndexPath;
@synthesize childController = _childController;
@synthesize selectedCell = _selectedCell;
@synthesize deliverable = _deliverable;
@synthesize numberFormatter = _numberFormatter;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize dateFormatter = _dateFormatter;
@synthesize popController = _popController;
@synthesize fetchRequest = _fetchRequest;
@synthesize expenseFRC = _expenseFRC;
@synthesize logger = _logger;
@synthesize theIndex = _theIndex;
@synthesize isNew = _isNew;
@synthesize lastSelected = _lastSelected;
@synthesize billedPredicate = _billedPredicate;
@synthesize unbilledPredicate = _unbilledPredicate;
@synthesize allPredicate = _allPredicate;
@synthesize displayOptions = _displayOptions;

#pragma mark - Delegate actions
-(void)releaseLogger{
    self.logger = nil;
}

-(void)didFinishWithError:(NSError *)error{
    [self dismissModalViewControllerAnimated:YES];    
}

-(void)didFinishWithResult:(MFMailComposeResult)result{
    if (result == MFMailComposeResultCancelled || result == MFMailComposeResultFailed) {
        // NSLog(@"Don't do anything");
    } else {
        for ( Deliverables *expense in self.project.projectExpense) {
            if ([expense.expensed integerValue] == 0 ) {
                expense.expensed = [NSNumber numberWithInt:1];
                expense.dateExpensed = [NSDate date];
            }
        }
       
        NSError *requestError = nil;
        if ([self.expenseFRC performFetch:&requestError]) {
            [self.tableView reloadData];
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - IBActions
-(IBAction)clickSummaryButton:(UIBarButtonItem *)sender{
    self.emailer = [[CCEmailer alloc] init];
    self.emailer.emailDelegate = self;
    self.expenseCalculator = [[CCExpenseReporterViewController alloc] init];
    
    self.emailer.subjectLine = [[NSString alloc] initWithFormat:@"Expense Report For: %@ As of %@", self.project.projectName, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.emailer.messageText = [self.expenseCalculator getExpenseReportForProject:self.project];
    [self.emailer sendEmail];
    [self.emailer addImageAttachments:self.expenseCalculator.receiptList];
    [self presentModalViewController:self.emailer.mailComposer animated:YES];
}

-(IBAction)clickTableDisplayOptions:(UISegmentedControl *)sender{
    self.lastSelected = sender.selectedSegmentIndex;
    
    if (sender.selectedSegmentIndex == 0) {
        [self.expenseFRC.fetchRequest setPredicate:self.unbilledPredicate];
    } else if (sender.selectedSegmentIndex == 1){
        [self.expenseFRC.fetchRequest setPredicate:self.billedPredicate];
    } else {
        [self.expenseFRC.fetchRequest setPredicate:self.allPredicate];
    }
    
    [self.expenseFRC performFetch:nil];
    [self.tableView reloadData];
    
}

-(BOOL)shouldShowCancelButton{
    return self.isNew;
}

-(IBAction)cancelPopover{
    [self.managedObjectContext save:nil];
    [self.managedObjectContext deleteObject:self.deliverable];
    [self.expenseFRC performFetch:nil];
    [self.tableView reloadData];
    self.deliverable = nil;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)savePopoverData{
    if (self.isNew && self.deliverable != nil) {
        self.deliverable.expenseProject = self.project;
        [self.project addProjectExpenseObject:self.deliverable];
        [self.managedObjectContext save:nil];
    }
}

-(IBAction)insertDeliverable{
    Deliverables *newDeliverable = [NSEntityDescription insertNewObjectForEntityForName:@"Expense" inManagedObjectContext:self.managedObjectContext];
    if (newDeliverable != nil) {
        newDeliverable.expensed = DELIVER_ACTIVE;
        newDeliverable.expenseProject = self.project;
        newDeliverable.datePaid = [NSDate date];
        self.deliverable = newDeliverable;
        self.isNew = YES;
        [self showDeliverableDetails:self.tableView rowIndex:nil];
    } else {
        // NSLog(@"Failed to create new deliverable");
    }
}

-(IBAction)doubleClickDeliverable:(UITapGestureRecognizer *)sender{
    CGPoint where = [sender locationInView:self.tableView];
    NSIndexPath* ip = [self.tableView indexPathForRowAtPoint:where];
    Deliverables *newDeliverable = [[self.project.projectExpense allObjects] objectAtIndex:[ip row]];
    if (newDeliverable.expensed == DELIVER_COMPLETE) {
        newDeliverable.expensed = DELIVER_ACTIVE;
    } else {
        newDeliverable.expensed = DELIVER_COMPLETE;
    }
    self.selectedIndexPath = ip;
    [self viewWillAppear:YES];
}

-(void)showDeliverableDetails:(UITableView *)tableView rowIndex:(NSIndexPath *)indexPath{
    self.childController.expense = self.deliverable;
    CGRect rect = self.view.frame;
    self.childController.contentSizeForViewInPopover = rect.size;
    self.childController.popControll = self.popController;
    self.childController.popDelegate = self;
    self.childController.controllingIndex = indexPath;
    [self.navigationController pushViewController:self.childController animated:YES];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self clickTableDisplayOptions:self.displayOptions];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *paidDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"datePaid" ascending:NO];
    NSSortDescriptor *purchaseDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pmtDescription" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: paidDateDescriptor, purchaseDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.expenseFRC.delegate = self;
    self.expenseFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:self.managedObjectContext
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.project = nil;
    self.selectedCell = nil;
    self.selectedIndexPath = nil;
    self.childController = nil;
    self.deliverable = nil;
    self.managedObjectContext = nil;
    self.numberFormatter = nil;
    self.popController = nil;
    self.fetchRequest = nil;
    self.expenseFRC = nil;
    self.theIndex = nil;
    self.unbilledPredicate = nil;
    self.billedPredicate = nil;
    self.allPredicate = nil;
    self.displayOptions = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

-(void)configureCell:(ExpenseCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    cell.paidTo.text = [[NSString alloc] initWithFormat:@"%@ on: %@",
                                 self.deliverable.paidTo,
                                 [self.dateFormatter stringFromDate:self.deliverable.datePaid]];
    if (self.deliverable.expensed == DELIVER_COMPLETE) {
        cell.imageView.image = [UIImage imageNamed:@"checkmark-box-small-green.png"];
        cell.description.text = self.deliverable.pmtDescription;
        if ([self.deliverable.milage floatValue] == 0 ) {
            cell.amountPaid.text = [self.numberFormatter stringFromNumber:self.deliverable.amount];
        } else {
            cell.amountPaid.text = nil;
        }
    } else if ([self.deliverable.milage floatValue ] > 0) {
        cell.imageView.image = [UIImage imageNamed:@"plane.png"];
        cell.description.text =  self.deliverable.pmtDescription;
        cell.amountPaid.text = nil;
    } else if ( self.deliverable.receipt != nil) {
        cell.imageView.image = [UIImage imageNamed:@"162-receipt.png"];
        cell.description.text =  self.deliverable.pmtDescription;
        cell.amountPaid.text = [self.numberFormatter stringFromNumber:self.deliverable.amount];
    } else {
        cell.imageView.image = nil;
        cell.description.text = self.deliverable.pmtDescription;
        cell.amountPaid.text = [self.numberFormatter stringFromNumber:self.deliverable.amount];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.expenseFRC sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.expenseFRC sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (ExpenseCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExpenseCell *cell = nil;
    static NSString *expensedCell = @"expenseCell";
    self.deliverable = [self.expenseFRC objectAtIndexPath:indexPath];
    
    cell = (ExpenseCell *)[tableView dequeueReusableCellWithIdentifier:expensedCell];
    if (cell == nil) {
        cell = [[ExpenseCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:expensedCell];
    }
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

-(void)deleteExpenseAtIndexPath:(NSIndexPath *)indexPath{
    self.expenseFRC.delegate = nil;
    if (indexPath != nil) {
        // We have to find it based upon deliverable which is already set in this instance
        self.deliverable = [self.expenseFRC objectAtIndexPath:indexPath];
    }
    // Test to see if the object exists...
    NSError *error = [[NSError alloc] init];
    @try {
        [self.managedObjectContext deleteObject:self.deliverable];
        if (![self.managedObjectContext save:&error]){
            self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
            [self.logger releaseLogger];
        }
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
        [self.logger releaseLogger];
    }
    
    NSError *fetchError = [[NSError alloc] init];
   @try {
        if (![self.expenseFRC performFetch:&fetchError]){
            self.logger = [[CCErrorLogger alloc] initWithError:fetchError andDelegate:self];
            [self.logger releaseLogger];
        } else {
            [self.tableView reloadData];
        }
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:fetchError andDelegate:self];
        [self.logger releaseLogger];
    }
    
    self.expenseFRC.delegate = self;
}


 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         // Delete the row from the data source
         [self deleteExpenseAtIndexPath:indexPath];
     }
     else if (editingStyle == UITableViewCellEditingStyleInsert) {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
 }

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
    self.selectedCell = (ExpenseCell *)[tableView cellForRowAtIndexPath:indexPath];
    self.selectedIndexPath = indexPath;
    self.deliverable = [self.expenseFRC objectAtIndexPath:indexPath];
    self.isNew = NO;
    [self showDeliverableDetails:tableView rowIndex:indexPath];
}

#pragma mark - Lazy Getter

-(CCExpenseDetailsViewController *)childController{
    if (_childController == nil) {
        _childController = [self.storyboard instantiateViewControllerWithIdentifier:@"expenseDetails"];
    }
    return _childController;
}

-(NSNumberFormatter *)numberFormatter{
    if (_numberFormatter == nil) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        [_numberFormatter setMinimumFractionDigits:2];
    }
    return _numberFormatter;
}

-(NSDateFormatter *)dateFormatter{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return _dateFormatter;
}

-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

-(NSManagedObjectContext *)managedObjectContext{
    if (_managedObjectContext == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = application.managedObjectContext;
        
    }
    return _managedObjectContext;
}

-(NSPredicate *)billedPredicate{
    if (_billedPredicate == nil) {
        NSString *filterProject = self.project.projectName;
        _billedPredicate = [NSPredicate predicateWithFormat:@"expenseProject.projectName == %@ AND expensed == 1", filterProject];
    }
    return _billedPredicate;
    
}

-(NSPredicate *)unbilledPredicate{
    if (_unbilledPredicate == nil) {
        NSString *filterProject = self.project.projectName;
        _unbilledPredicate = [NSPredicate predicateWithFormat:@"expenseProject.projectName == %@ AND expensed == 0", filterProject];
    }
    return _unbilledPredicate;
    
}

-(NSPredicate *)allPredicate{
    if (_allPredicate == nil) {
        NSString *filterProject = self.project.projectName;
        _allPredicate = [NSPredicate predicateWithFormat:@"expenseProject.projectName == %@", filterProject];
    }
    return _allPredicate;
}

@end
