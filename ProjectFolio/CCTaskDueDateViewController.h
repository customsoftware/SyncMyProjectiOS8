//
//  CCTaskDueDateViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import <UIKit/UIKit.h>
#import "Task.h"

@interface CCTaskDueDateViewController : UIViewController<UIAlertViewDelegate>

@property (strong, nonatomic) Task *activeTask;
@property (strong, nonatomic) IBOutlet UIDatePicker *dueDate;

-(IBAction)setTaskDueDate:(UIDatePicker *)sender;
-(IBAction)pushIntoReminder:(UISegmentedControl *)sender;
-(IBAction)changeDueDate:(UISegmentedControl *)sender;

@end
