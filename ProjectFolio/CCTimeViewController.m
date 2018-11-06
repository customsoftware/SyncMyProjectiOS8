//
//  CCTimeViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import "CCTimeViewController.h"

#define TIME_UNBILLED [[NSNumber alloc] initWithInt:0]
#define TIME_BILLED [[NSNumber alloc] initWithInt:1]
#define UNBILLED 0
#define BILLED 1

@interface CCTimeViewController ()

@property  (strong, nonatomic) CCErrorLogger *logger;
@end

@implementation CCTimeViewController

#pragma mark - IBActions
-(void)setTimerList:(UISegmentedControl *)sender{
    NSArray *workingArray = [self.project.projectWork allObjects];
    [self.displayTimers removeAllObjects];
    for (WorkTime *time in workingArray) {
        if (sender.selectedSegmentIndex == UNBILLED) {
            if ([time.billed intValue] == UNBILLED) {
                [self.displayTimers addObject:time];
            }
        } else if (sender.selectedSegmentIndex == BILLED){
            if ([time.billed intValue] == BILLED) {
                [self.displayTimers addObject:time];
            }
        } else {
            [self.displayTimers addObject:time];

        }
    }
    NSSortDescriptor *startDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:startDescriptor, nil];
    [self.displayTimers sortUsingDescriptors:sortDescriptors];
}

-(IBAction)timeTypeSelected:(UISegmentedControl *)sender{
    [self setTimerList:sender];
    [self.tableView reloadData];
}

-(void)releaseLogger{
    self.logger = nil;
}

- (IBAction)toggleEditing:(UIBarButtonItem *)sender{
    self.tableView.editing = !self.tableView.editing;
    if (self.tableView.editing) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleEditing:)];
        self.navigationItem.rightBarButtonItem = editButton;
    } else {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}

#pragma mark - Table View Tasks
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.displayTimers count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
       if (indexPath.row == 0 && self.timeSelector.selectedSegmentIndex == 0 ) {
           UIAlertView *alert = [[ UIAlertView alloc] initWithTitle:@"Unallowed action" message:@"You can't deleted the active timer" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
           [alert show];
       } else {
        
            // Delete the managed object for the given index path
            [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:[self.displayTimers objectAtIndex:[indexPath row]]];
            [self.displayTimers removeObjectAtIndex:[indexPath row]];
             
            // Save the context.
            NSError *error = [[NSError alloc] init];
            @try {
                if (![[[CoreData sharedModel:nil] managedObjectContext] save:&error]){
                    self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                    [self.logger releaseLogger];
                }
            }
            @catch (NSException *exception) {
                self.logger = [[CCErrorLogger alloc] initWithError:error andDelegate:self];
                [self.logger releaseLogger];
            }
            [tableView deleteRowsAtIndexPaths:[[NSArray alloc] initWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"timeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update the detail view contents
    self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    self.selectedIndexPath = indexPath;
    self.time = [self.displayTimers objectAtIndex:[indexPath row]];
    if (self.selectedCell.imageView.image == nil) {
        //self.childController.activeTask = self.task;
        CGRect rect = self.view.frame;
        self.childController.preferredContentSize = rect.size;
        self.childController.timer = self.time;
        [self.navigationController pushViewController:self.childController animated:YES];
    }
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    WorkTime *newTime = [self.displayTimers objectAtIndex:[indexPath row]];
    double eTime = [newTime.elapseTime integerValue];
    NSString *elapseTimeString = [self.numberFormatter stringFromNumber:[[NSNumber alloc] initWithDouble:eTime/60]];
    cell.textLabel.text = [[NSString alloc] initWithFormat:@"Elapse time: %@ minutes", elapseTimeString];
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ - %@", [self.dateFormatter stringFromDate:newTime.start], [self.endDateFormatter stringFromDate:newTime.end]];
    if (indexPath.row == 0 && self.timeSelector.selectedSegmentIndex == 0 ) {
        cell.imageView.image = [UIImage imageNamed:@"117-todo.png"];
    } else {
        cell.imageView.image = nil;
    }
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    self.endDateFormatter = [[NSDateFormatter alloc] init];
    [self.endDateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [self.endDateFormatter setDateStyle:NSDateFormatterNoStyle];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.numberFormatter setMaximumFractionDigits:2];
    
    self.displayTimers = [[NSMutableArray alloc] init];
    self.startup = NO;
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
    self.navigationItem.rightBarButtonItem = editButton;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.timeSelector.selectedSegmentIndex = [self.timeSelectorDelegate getSelectedSegment];
    [self timeTypeSelected:self.timeSelector];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Lazy instantiators
-(CCTimerDetailsViewController *)childController{
    if (_childController == nil) {
        _childController = [self.storyboard instantiateViewControllerWithIdentifier:@"timerDetails"];
    }
    return _childController;
}

@end
