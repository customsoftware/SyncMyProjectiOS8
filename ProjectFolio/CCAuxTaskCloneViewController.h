//
//  CCAuxTaskCloneViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/5/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "CCAppDelegate.h"
#import "Task.h"
#import "CCAuxTaskCloneDrillController.h"
#import "CCProjectTaskDelegate.h"

@interface CCAuxTaskCloneViewController : UITableViewController<NSFetchedResultsControllerDelegate,UIActionSheetDelegate,CCProjectTaskDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *projectFRC;
@property (strong, nonatomic) Project *selectedProject;

-(Project *)getActiveProject;
-(Task *)getSelectedTask;
-(Project *)getControllingProject;

@end
