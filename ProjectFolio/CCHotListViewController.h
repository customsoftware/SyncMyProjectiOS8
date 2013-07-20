//
//  CCHotListViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/21/12.
//
//

#import <UIKit/UIKit.h>
#import "CCAppDelegate.h"
#import "Task.h"
#import "Project+CategoryProject.h"
#import "CCTaskViewDetailsController.h"
#import "CCPopoverControllerDelegate.h"
#import "CCEmailer.h"
#import "CCHotListReportViewController.h"
#import "CCProjectTimer.h"

@class CCDetailViewController;

@interface CCHotListViewController : UIViewController<CCEmailDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,CCPopoverControllerDelegate,UISearchBarDelegate>
@property (strong, nonatomic) CCDetailViewController *projectDetailController;
@property (strong, nonatomic) Task *task;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *taskFRC;
@property (strong, nonatomic) CCProjectTimer *projectTimer;
@property (strong, nonatomic) NSIndexPath * selectedIndex;



@end
