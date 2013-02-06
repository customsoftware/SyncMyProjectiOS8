//
//  CCTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/1/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Task.h"
#import "CCTaskViewDetailsController.h"
#import "CCAppDelegate.h"
#import "CCNullSortDescriptor.h"
#import "CCPopoverControllerDelegate.h"
#import "CCTaskSummaryViewController.h"

@interface CCTaskViewController : UITableViewController<CCPopoverControllerDelegate,UIAlertViewDelegate,NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Task *task;
//@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
//@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (strong, nonatomic) CCTaskViewDetailsController *childController;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *taskFRC;
@property (strong, nonatomic) CCTaskSummaryViewController *summaryController;

-(IBAction)insertTask;
-(IBAction)clickSummary:(UISegmentedControl *)sender;
-(IBAction)cancelPopover;
-(IBAction)savePopoverData;
-(BOOL)shouldShowCancelButton;


@end
