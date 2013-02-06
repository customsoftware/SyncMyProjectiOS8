//
//  CCSubTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/27/12.
//
//

#import <UIKit/UIKit.h>
#import "Task.h"
#import "CCAppDelegate.h"
#import "Project.h"
#import "CCProjectTaskDelegate.h"
#import "CCTaskViewDetailsController.h"
#import "CCPopoverControllerDelegate.h"

@interface CCSubTaskViewController : UIViewController<CCPopoverControllerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) id<CCProjectTaskDelegate> projectDelegate;
@property (strong, nonatomic) Task *controllingTask;

-(IBAction)editButton:(UIBarButtonItem *)sender;
-(BOOL)shouldShowCancelButton;

@end
