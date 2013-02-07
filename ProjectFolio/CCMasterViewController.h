//
//  CCMasterViewController.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 Ken Cluff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "WorkTime.h"
#import "CCGeneralCloser.h"
#import "CCMainTaskViewController.h"
#import "CCProjectTaskDelegate.h"
#import "CCProjectTimer.h"
#import "CCErrorLogger.h"
#import <CoreData/CoreData.h>
#import "CCDateSetterViewController.h"
#import "CCTextEntryPopoverController.h"
#import "CCSettingsControl.h"
#import "CoreData.h"

@class CCDetailViewController;


@interface CCMasterViewController : UIViewController <UIPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate, UIAlertViewDelegate,UIActionSheetDelegate,MFMailComposeViewControllerDelegate,CCProjectTaskDelegate,UISearchDisplayDelegate,CCLoggerDelegate,CoreDataDelegate>

@property (strong, nonatomic) CCTextEntryPopoverController *projectNameView;
@property (strong, nonatomic) CCDetailViewController *detailViewController;
@property (strong, nonatomic) UINavigationController *projectDateController;
@property (strong, nonatomic) UIPopoverController *projectPopover;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (strong, nonatomic) UITableViewCell *controllingCell;
@property (strong, nonatomic) NSIndexPath *controllingCellIndex;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *projectActionsButton;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView;
-(IBAction)filterActions:(UISegmentedControl *)sender;
-(IBAction)actionButton:(UIBarButtonItem *)sender;
-(void)setFontForDisplay;
-(Project *)getActiveProject;
-(void)releaseLogger;
-(void)persistentStoreDidChange;

@end
