//
//  CCiPhoneTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/28/12.
//
//

#import <UIKit/UIKit.h>
#import "Task.h"
#import "CCAppDelegate.h"
#import "Project.h"
#import "CCProjectTaskDelegate.h"
#import "CCTaskViewDetailsController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCSubTaskViewController.h"
#import "CCTaskSummaryViewController.h"
#import "CCChart.h"
#import "CCErrorLogger.h"
#import "CCiPhoneDetailViewController.h"

@interface CCiPhoneTaskViewController : UIViewController<CCTaskSummaryDelegate,CCPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,CCTaskChartDelegate,CCLoggerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *displayOptions;
@property (weak, nonatomic) id<CCProjectTaskDelegate> projectDelegate;
@property (strong, nonatomic) IBOutlet UISegmentedControl *navButton;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiper;
- (IBAction)goToNotes:(UIBarButtonItem *)sender;

-(IBAction)displayOptions:(UISegmentedControl *)sender;
-(IBAction)cancelPopover;
-(IBAction)savePopoverData;
-(BOOL)shouldShowCancelButton;
-(void)cancelSummaryChart;
-(Project *)getControllingProject;
-(void)releaseLogger;


@end
