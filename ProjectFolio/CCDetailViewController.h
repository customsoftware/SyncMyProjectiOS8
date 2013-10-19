//
//  CCDetailViewController.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "CCProjectTimer.h"
#import "CCPopoverControllerDelegate.h"
#import "CCTimerSummaryViewController.h"
#import "CCCalendarViewController.h"
#import "CCDeliverableViewController.h"
#import "CCProjectChartViewController.h"
#import "CCModalViewDelegate.h"
#import "CCEmailer.h"
#import "CCLatestNewsViewController.h"


@interface CCDetailViewController : UIViewController <CCProjectTaskDelegate,UIPopoverControllerDelegate, UISplitViewControllerDelegate,CCModalViewDelegate,UIActionSheetDelegate,CCEmailDelegate,CCLoggerDelegate,CCTaskSummaryDelegate,UIGestureRecognizerDelegate,UIPrintInteractionControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) CCProjectTimer *activeTimer;

@property (strong, nonatomic) CCDeliverableViewController *deliverable;
@property (strong, nonatomic) CCCalendarViewController *calendar;
@property (strong, nonatomic) CCTimerSummaryViewController *time;
@property (strong, nonatomic) CCProjectChartViewController *projectChart;

@property (weak, nonatomic) IBOutlet UITextView *projectNotes;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showDeliverables;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showCalendar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showTimers;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showTaskChart;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeDown;

-(IBAction)showDeliverablePopover:(id)sender;
-(IBAction)showTimePopover:(id)sender;
-(IBAction)showCalendarPopover:(id)sender;
-(IBAction)showChart:(UIBarButtonItem *)sender;
-(IBAction)sendNotes:(UIButton *)sender;
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