//
//  CCTimeViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Calendar.h"
#import "CCCalendarMeetingPlannerViewController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "CCAppDelegate.h"
#import "CCErrorLogger.h"

@interface CCCalendarViewController : UITableViewController<EKEventEditViewDelegate,EKEventViewDelegate,CCLoggerDelegate>

@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Calendar *meeting;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (strong, nonatomic) EKEventEditViewController *childController;
@property (strong, nonatomic) EKEventViewController *calendarController;
@property (strong, nonatomic) NSDateFormatter *endDateFormatter;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiper;

-(void)releaseLogger;

@end
