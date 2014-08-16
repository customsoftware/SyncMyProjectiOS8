//
//  CCDeliverableViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Deliverables.h"
#import "CCExpenseDetailsViewController.h"
#import "CCAppDelegate.h"
#import "ExpenseCell.h"
#import "CCPopoverControllerDelegate.h"
#import "CCExpenseReporterViewController.h"
#import "CCEmailer.h"
#import "CCErrorLogger.h"

@interface CCDeliverableViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,CCPopoverControllerDelegate,CCEmailDelegate,CCLoggerDelegate,UIActionSheetDelegate,UIPrintInteractionControllerDelegate>

@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *expenseFRC;
@property (strong, nonatomic) CCExpenseDetailsViewController *childController;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (strong, nonatomic) ExpenseCell *selectedCell;
@property (strong, nonatomic) Deliverables *deliverable;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) UIPopoverController *popController;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiper;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *displayOptions;

-(void)releaseLogger;
-(BOOL)shouldShowCancelButton;

@end
