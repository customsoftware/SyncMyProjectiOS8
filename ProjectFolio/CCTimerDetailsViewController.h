//
//  CCTimerDetailsViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/14/12.
//
//

#import <UIKit/UIKit.h>
#import "WorkTime.h"
#import "Project.h"
#import "CCProjectSwitchTableViewController.h"

@interface CCTimerDetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIDatePicker *changeDate;
@property (strong, nonatomic) IBOutlet UISwitch *billed;
@property (strong, nonatomic) WorkTime *timer;
@property (strong, nonatomic) CCProjectSwitchTableViewController *childController;

-(IBAction)billed:(UISwitch *)sender;
-(IBAction)changeDate:(UIDatePicker *)sender;

@end
