//
//  CCTimerDetailsViewController.m
//  SyncMyProject
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
@property (strong, nonatomic) CCProjectSwitchTableViewController *childController;
@property BOOL startTime;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIDatePicker *changeDate;
@property (weak, nonatomic) IBOutlet UISwitch *billed;

@end

@implementation CCTimerDetailsViewController
@synthesize dateFormatter = _dateFormatter;
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
        retValue = 2;
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
        if (indexPath.row == 0) {
            returnCell = [tableView dequeueReusableCellWithIdentifier:projectCell];
            returnCell.detailTextLabel.text = self.timer.workProject.projectName;
        } else {
            returnCell = [tableView dequeueReusableCellWithIdentifier:projectCell];
            returnCell.textLabel.text = @"Owning Task";
            returnCell.accessoryType = UITableViewCellAccessoryNone;
            returnCell.detailTextLabel.text = ( self.timer.workTask.title != nil ) ? self.timer.workTask.title : @"None selected";
        }
    }
    
    return returnCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0){
            self.changeDate.minimumDate = nil;
            self.changeDate.date = self.timer.start;
            self.changeDate.maximumDate = self.timer.end;
            self.startTime = YES;
        } else {
            self.changeDate.minimumDate = self.timer.start;
            self.changeDate.date = self.timer.end;
            self.changeDate.maximumDate = nil;
            self.startTime = NO;
        }
    } else {
        CGRect rect = self.view.frame;
        self.childController.preferredContentSize = rect.size;
        self.childController.selectedProject = self.timer.workProject;
        self.childController.currentTimer = self.timer;
        BOOL showList = YES;
        if (indexPath.row == 0) {
            // This is a project
            self.childController.currentTask = nil;
        } else {
            // This is a task
            if (self.timer.workProject.projectTask.allObjects.count > 0) {
                self.childController.currentTask = self.timer.workTask != nil ? self.timer.workTask : [self.timer.workProject.projectTask allObjects][0];
            } else {
                self.childController.currentTask = nil;
                showList = NO;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Tasks to Show" message:@"Since there are no tasks in this project, there are none to assign to this time slice" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
        if (showList) {
            [self.navigationController pushViewController:self.childController animated:YES];
        }
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.billed setOn:[self.timer.billed boolValue]];
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
