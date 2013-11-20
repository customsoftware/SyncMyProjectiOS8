//
//  CCiPhoneMasterViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 11/26/12.
//
//

#import <UIKit/UIKit.h>
#import "Project+CategoryProject.h"
#import "WorkTime.h"
#import "CCGeneralCloser.h"
#import "CCGeneralCloserProtocol.h"
#import "CCiPhoneTaskViewController.h"
#import "CCProjectTaskDelegate.h"
#import "CCProjectTimer.h"
#import "CCErrorLogger.h"
#import "CCDateSetterViewController.h"
#import "CCTextEntryPopoverController.h"
#import "CCSettingsControl.h"
#import "CoreData.h"

@interface CCiPhoneMasterViewController : UIViewController <UIPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate, UIAlertViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,CCProjectTaskDelegate,UISearchDisplayDelegate,CCLoggerDelegate,CoreDataDelegate,UISearchBarDelegate,CCGeneralCloserProtocol,UIPrintInteractionControllerDelegate>

@property (strong, nonatomic) CCTextEntryPopoverController *projectNameView;
@property (strong, nonatomic) CCDateSetterViewController *projectPopover;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) UITableViewCell *controllingCell;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiper;

-(Project *)getActiveProject;
-(void)releaseLogger;
-(void)persistentStoreDidChange;

@end
