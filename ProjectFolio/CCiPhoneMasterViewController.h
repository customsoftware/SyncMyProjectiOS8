//
//  CCiPhoneMasterViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/26/12.
//
//

#import <UIKit/UIKit.h>
#import "Project+CategoryProject.h"
#import "WorkTime.h"
#import "CCGeneralCloser.h"
#import "CCiPhoneTaskViewController.h"
#import "CCProjectTaskDelegate.h"
#import "CCProjectTimer.h"
#import "CCErrorLogger.h"
#import <CoreData/CoreData.h>
#import "CCDateSetterViewController.h"
#import "CCTextEntryPopoverController.h"
#import "CCSettingsControl.h"
#import "CoreData.h"

@interface CCiPhoneMasterViewController : UIViewController <UIPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate, UIAlertViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,CCProjectTaskDelegate,UISearchDisplayDelegate,CCLoggerDelegate,CoreDataDelegate>

@property (strong, nonatomic) CCTextEntryPopoverController *projectNameView;
// @property (strong, nonatomic) CCDetailViewController *detailViewController;
// @property (strong, nonatomic) UINavigationController *projectDateController;
// @property (strong, nonatomic) UIPopoverController *projectPopover;
@property (strong, nonatomic) CCDateSetterViewController *projectPopover;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) UITableViewCell *controllingCell;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *projectActionsButton;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

-(IBAction)filterActions:(UISegmentedControl *)sender;
-(IBAction)actionButton:(UIBarButtonItem *)sender;
-(Project *)getActiveProject;
-(void)releaseLogger;
-(void)persistentStoreDidChange;

@end
