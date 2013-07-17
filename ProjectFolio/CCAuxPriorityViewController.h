//
//  CCAuxPriorityViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import <UIKit/UIKit.h>
#import "CCAppDelegate.h"
#import "Priority.h"
#import "CCAuxPriorityEditorViewController.h"
#import "CCErrorLogger.h"

@interface CCAuxPriorityViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,CCPriorityDetailDelegate>

-(IBAction)insertPriority:(UIBarButtonItem * )sender;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
