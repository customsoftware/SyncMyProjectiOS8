//
//  CCMainTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/21/12.
//
//

#import <UIKit/UIKit.h>
#import "Task.h"
// #import "CCAppDelegate.h"
#import "Project.h"
#import "CCProjectTaskDelegate.h"
#import "CCTaskViewDetailsController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCSubTaskViewController.h"
#import "CCTaskSummaryViewController.h"
#import "CCChart.h"
#import "CCErrorLogger.h"
#import "CoreData.h"

@interface CCMainTaskViewController : UIViewController<CCTaskSummaryDelegate,CCPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,CCTaskChartDelegate,CCLoggerDelegate,CoreDataDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *displayOptions;
@property (weak, nonatomic) id<CCProjectTaskDelegate> projectDelegate;
@property (strong, nonatomic) IBOutlet UISegmentedControl *navButton;

-(IBAction)displayOptions:(UISegmentedControl *)sender;
-(IBAction)cancelPopover;
-(IBAction)savePopoverData;
-(IBAction)navButton:(UISegmentedControl *)sender;
-(BOOL)shouldShowCancelButton;
-(void)cancelSummaryChart;
-(Project *)getControllingProject;
-(void)releaseLogger;
-(void)persistentStoreDidChange;

@end
