//
//  CCTimerDetailsViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/14/12.
//
//

#import "CCTimerDetailsViewController.h"
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]


@interface CCTimerDetailsViewController ()
@property (weak, nonatomic) UITableViewCell *selectedCell;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property BOOL startTime;

@end

@implementation CCTimerDetailsViewController
@synthesize billed = _billed;
@synthesize tableView = _tableView;
@synthesize changeDate = _changeDate;
@synthesize selectedCell = _selectedCell;
@synthesize dateFormatter = _dateFormatter;
@synthesize timer = _time;
@synthesize startTime = _startTime;
@synthesize childController = _childController;

#pragma makr - IBOutlets and Actions
-(IBAction)billed:(UISwitch *)sender{
    self.timer.billed = ([sender isOn]) ? SWITCH_ON:SWITCH_OFF;
}

-(IBAction)changeDate:(UIDatePicker *)sender{
    self.selectedCell.detailTextLabel.text = [self.dateFormatter stringFromDate:sender.date];
    if (self.startTime == YES) {
        self.timer.start = sender.date;
    } else {
        self.timer.end = sender.date;
    }
}

#pragma mark - Table View methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int retValue;
    if (section == 0) {
        retValue = 2;
    } else {
        retValue = 1;
    }
    
    return retValue;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *dateCell = @"timerCell";
    static NSString *projectCell = @"timerOwnerCell";
    UITableViewCell *returnCell = nil;
    if (indexPath.section == 0) {
        returnCell = [tableView dequeueReusableCellWithIdentifier:dateCell];
        if (indexPath.row == 0){
            returnCell.textLabel.text = @"Start Time:";
            returnCell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.timer.start];
        } else {
            returnCell.textLabel.text = @"End Time:";
            if (self.timer.end == nil) {
                self.timer.end = self.timer.start;
            }
            returnCell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.timer.end];
        }
    } else {
        returnCell = [tableView dequeueReusableCellWithIdentifier:projectCell];
        returnCell.detailTextLabel.text = self.timer.workProject.projectName;
    }
    
    return returnCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0){
            self.changeDate.date = self.timer.start;
            self.startTime = YES;
        } else {
            self.changeDate.date = self.timer.end;
            self.startTime = NO;
        }
    } else {
        CGRect rect = self.view.frame;
        self.childController.contentSizeForViewInPopover = rect.size;
        self.childController.selectedProject = self.timer.workProject;
        self.childController.currentTimer = self.timer;
        [self.navigationController pushViewController:self.childController animated:YES];
    }
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.billed = nil;
    self.tableView = nil;
    self.changeDate = nil;
    self.selectedCell = nil;
    self.timer = nil;
    self.childController = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.tableView reloadData];
    BOOL activeVal = (self.timer.billed == SWITCH_ON) ? YES:NO;
    [self.billed setOn:activeVal];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Lazy Getters
-(NSDateFormatter *)dateFormatter{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterLongStyle;
    }
    return _dateFormatter;
}

-(CCProjectSwitchTableViewController *)childController{
    if (_childController == nil) {
        _childController = [self.storyboard instantiateViewControllerWithIdentifier:@"projectList"];
    }
    return _childController;
}


@end
