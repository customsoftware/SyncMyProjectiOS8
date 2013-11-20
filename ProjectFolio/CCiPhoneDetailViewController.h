//
//  CCiPhoneDetailViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 11/28/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "CCTimerSummaryViewController.h"
#import "CCTaskSummaryViewController.h"
#import "CCCalendarViewController.h"
#import "CCDeliverableViewController.h"
#import "CCProjectTimer.h"
#import "CCProjectChartViewController.h"
#import "CCModalViewDelegate.h"
#import "CCAuxSettingsViewController.h"
#import "CCEmailer.h"
#import "CCErrorLogger.h"
#import "CCProjectTaskDelegate.h"

@interface CCiPhoneDetailViewController : UIViewController <CCProjectTaskDelegate,UIPopoverControllerDelegate, UISplitViewControllerDelegate,CCModalViewDelegate,UIActionSheetDelegate,CCEmailDelegate,CCLoggerDelegate,CCTaskSummaryDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) IBOutlet UITextView *projectNotes;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) CCProjectTimer *activeTimer;

@property (strong, nonatomic) CCDeliverableViewController *deliverable;
@property (strong, nonatomic) CCCalendarViewController *calendar;
@property (strong, nonatomic) CCTimerSummaryViewController *time;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showDeliverables;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showCalendar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showTimers;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showTaskChart;


-(IBAction)showDeliverablePopover:(id)sender;
-(IBAction)showTimePopover:(id)sender;
-(IBAction)showCalendarPopover:(id)sender;
-(IBAction)sendNotes:(UIBarButtonItem *)sender;
-(IBAction)showSettings:(UIBarButtonItem *)sender;
-(IBAction)showTaskChart:(UIBarButtonItem *)sender;

-(Project *)getControllingProject;
-(void)cancelSummaryChart;
-(void)dismissModalView:(UIView *)sender;
-(Project *)getActiveProject;
-(void)didFinishWithError:(NSError *)error;
-(void)didFinishWithResult:(MFMailComposeResult)result;
-(void)releaseLogger;

@end
