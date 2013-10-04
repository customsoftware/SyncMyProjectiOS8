//
//  CCDeliverableViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import "CCDeliverableViewController.h"
#import "CCPrintNotesRender.h"
#define kFontNameKey @"font"
#define kFontSize @"fontSize"

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

#pragma mark - Delegate actions
-(void)releaseLogger{
    self.logger = nil;
}

-(void)didFinishWithError:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];    
}

-(void)didFinishWithResult:(MFMailComposeResult)result{
    if (result == MFMailComposeResultCancelled || result == MFMailComposeResultFailed) {
        // NSLog(@"Don't do anything");
    } else {
        [self expenseOutDeliveredItems];
        
        NSError *requestError = nil;
        if ([self.expenseFRC performFetch:&requestError]) {
            [self.tableView reloadData];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController{
    
}

#pragma mark - IBActions
-(IBAction)clickSummaryButton:(UIBarButtonItem *)sender{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Expense Report Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"EMail", @"Print", nil];
    [sheet showInView:self.view.superview];
    //[self sendToPrinter];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            [self sendAsEmail];
            break;
        
        case 1:
            [self sendToPrinter];
            break;
            
        default:
            break;
    }
}

- (void)sendAsEmail{
    self.emailer = [[CCEmailer alloc] init];
    self.emailer.emailDelegate = self;
    self.expenseCalculator = [[CCExpenseReporterViewController alloc] init];
    
    self.emailer.subjectLine = [[NSString alloc] initWithFormat:@"Expense Report For: %@ As of %@", self.project.projectName, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.emailer.messageText = [self.expenseCalculator getExpenseReportForProject:self.project];
    self.emailer.useHTML = [NSNumber numberWithBool:YES];
    [self.emailer sendEmail];
    [self.emailer addImageAttachments:self.expenseCalculator.receiptList];
    [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
}

- (void)sendToPrinter{
    self.expenseCalculator = [[CCExpenseReporterViewController alloc] init];
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.jobName = self.project.projectName;
    pic.printingItems = [self getReceiptsForProject:self.project];
    pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *notesFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                  initWithMarkupText:[self.expenseCalculator getExpenseReportForProject:self.project]];
    notesFormatter.startPage = 0;
    CCPrintNotesRender *renderer = [[CCPrintNotesRender alloc] init];
    renderer.headerString = [[NSString alloc] initWithFormat:@"Expense Report For: %@ As of %@", self.project.projectName, [self.dateFormatter stringFromDate:[NSDate date]]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    renderer.fontName = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    renderer.fontSize = [defaults integerForKey:kFontSize];
    [renderer addPrintFormatter:notesFormatter startingAtPageAtIndex:0];
    pic.printPageRenderer = renderer;
    pic.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        } else if ( completed && !error) {
            [self expenseOutDeliveredItems];
        }
    };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
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
    
    [self resetTableView];
}

- (void)resetTableView {
    [self.expenseFRC performFetch:nil];
    [self.tableView reloadData];
}

-(BOOL)shouldShowCancelButton{
    return self.isNew;
}

-(IBAction)cancelPopover{
    [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.deliverable];
    [self.expenseFRC performFetch:nil];
    [self.tableView reloadData];
    self.deliverable = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)savePopoverData{
    if (self.isNew && self.deliverable != nil) {
        self.deliverable.expenseProject = self.project;
        [self.project addProjectExpenseObject:self.deliverable];
        [self.project.managedObjectContext save:nil];
    }
}

-(IBAction)insertDeliverable{
    Deliverables *newDeliverable = [CoreData createExpenseInProject:self.project];
    if (newDeliverable != nil) {
        newDeliverable.expensed = DELIVER_ACTIVE;
        newDeliverable.datePaid = [NSDate date];
        self.deliverable = newDeliverable;
        self.isNew = YES;
        [self showDeliverableDetails:self.tableView rowIndex:nil];
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
    self.childController.preferredContentSize = rect.size;
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
    [super viewWillAppear:animated];
    self.swiper.enabled = YES;
    [self clickTableDisplayOptions:self.displayOptions];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.swiper.enabled = NO;
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Add swipe gesture recognizer to add expenses
    self.swiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(insertDeliverable)];
    [self.swiper setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.navigationController.navigationBar addGestureRecognizer:self.swiper];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTableView) name:kiCloudSyncNotification object:nil];
	// Do any additional setup after loading the view.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *paidDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"datePaid" ascending:NO];
    NSSortDescriptor *purchaseDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pmtDescription" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: paidDateDescriptor, purchaseDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.expenseFRC.delegate = self;
    self.expenseFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

-(void)configureCell:(ExpenseCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    cell.paidTo.text = [[NSString alloc] initWithFormat:@"%@ on: %@",
                                 self.deliverable.paidTo,
                                 [self.dateFormatter stringFromDate:self.deliverable.datePaid]];
    if (self.deliverable.expensed == DELIVER_COMPLETE) {
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
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
    } else if ( self.deliverable.receiptPath != nil) {
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
        
        // Delete the image if there is one...
        if (self.deliverable.receiptPath) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", [self getDocumentsDirectory],self.deliverable.receiptPath];
            // Delete the file
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            [fileManager removeItemAtPath:fullPath error:&error];
        }

        [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:self.deliverable];
        if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
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

#pragma mark - Helpers
- (NSString *)getDocumentsDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

- (NSArray *)getReceiptsForProject:(Project *)project {
    NSMutableArray *workingList = [[NSMutableArray alloc] init];
    NSSortDescriptor *expenseDate = [[NSSortDescriptor alloc]initWithKey:@"datePaid" ascending:YES];
    NSArray *sortList = [[NSArray alloc] initWithObjects:expenseDate, nil];
    NSArray *expenses = [project.projectExpense sortedArrayUsingDescriptors:sortList];
    NSString *documentString = [self getDocumentsDirectory];
    for (Deliverables *expense in expenses) {
        if (![expense.expensed boolValue] && expense.receiptPath) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentString,expense.receiptPath];
            UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
            [workingList addObject:image];
        }
    }
    return workingList;
}

- (void)expenseOutDeliveredItems {
    for ( Deliverables *expense in self.project.projectExpense) {
        if ([expense.expensed integerValue] == 0 ) {
            expense.expensed = [NSNumber numberWithInt:1];
            expense.dateExpensed = [NSDate date];
        }
    }
}

#pragma mark - Accessors
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
