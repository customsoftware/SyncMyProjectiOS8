//
//  CCMasterViewController.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 Ken Cluff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project+CategoryProject.h"
#import "WorkTime.h"
#import "CCGeneralCloser.h"
#import "CCMainTaskViewController.h"
#import "CCProjectTaskDelegate.h"
#import "CCProjectTimer.h"
#import "CCErrorLogger.h"
#import "CCDateSetterViewController.h"
#import "CCTextEntryPopoverController.h"
#import "CCSettingsControl.h"
#import "CoreData.h"
#import "CCGeneralCloserProtocol.h"
#import "CCPopoverControllerDelegate.h"

@class CCDetailViewController;


@interface CCMasterViewController : UIViewController <UIPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate, UIAlertViewDelegate,UIActionSheetDelegate,CCProjectTaskDelegate,UISearchDisplayDelegate,UISearchBarDelegate,CCLoggerDelegate,CoreDataDelegate,UIPrintInteractionControllerDelegate,CCGeneralCloserProtocol,CCPopoverControllerDelegate>

@property (strong, nonatomic) CCTextEntryPopoverController *projectNameView;
@property (strong, nonatomic) CCDetailViewController *detailViewController;
@property (strong, nonatomic) UINavigationController *projectDateController;
@property (strong, nonatomic) UIPopoverController *projectPopover;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) UITableViewCell *controllingCell;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *projectActionsButton;
@property (strong, nonatomic) UISwipeGestureRecognizer *swiper;
@property (weak, nonatomic) IBOutlet UISegmentedControl *filterSegmentControl;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView;
- (IBAction)filterActions:(UISegmentedControl *)sender;
- (IBAction)actionButton:(UIBarButtonItem *)sender;
- (void)setFontForDisplay;
- (Project *)getActiveProject;
- (void)releaseLogger;
- (void)persistentStoreDidChange;
- (void)sendOutput;

@end
