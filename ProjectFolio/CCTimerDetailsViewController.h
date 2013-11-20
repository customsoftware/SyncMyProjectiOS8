//
//  CCTimerDetailsViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 8/14/12.
//
//

#import <UIKit/UIKit.h>
#import "WorkTime.h"
#import "Project.h"
#import "CCProjectSwitchTableViewController.h"

@interface CCTimerDetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) WorkTime *timer;

-(IBAction)billed:(UISwitch *)sender;
-(IBAction)changeDate:(UIDatePicker *)sender;

@end
