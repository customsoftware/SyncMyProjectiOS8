//
//  CCAuxTaskCloneDrillController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 11/5/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "CCAppDelegate.h"
#import "Task.h"
#import "CCProjectTaskDelegate.h"

@interface CCAuxTaskCloneDrillController : UITableViewController<NSFetchedResultsControllerDelegate,UIActionSheetDelegate,CCProjectTaskDelegate>

@property (weak, nonatomic) id<CCProjectTaskDelegate> projectDelegate;

-(Project *)getActiveProject;
-(Task *)getSelectedTask;

@end
