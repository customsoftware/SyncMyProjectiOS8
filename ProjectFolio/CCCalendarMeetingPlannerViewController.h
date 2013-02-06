//
//  CCCalendarMeetingPlannerViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import <UIKit/UIKit.h>
#import "Calendar.h"
#import "CCAppDelegate.h"

@interface CCCalendarMeetingPlannerViewController : UIViewController

@property (strong, nonatomic) Calendar *meeting;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) IBOutlet UITextField *eventName;
@property (strong, nonatomic) IBOutlet UIDatePicker *startTime;

-(IBAction)showEventName:(UITextField *)eventName;
-(IBAction)setMeetingStartTime:(UIDatePicker *)sender;
-(IBAction)pushIntoCalendar:(UIButton *)sender;

@end
