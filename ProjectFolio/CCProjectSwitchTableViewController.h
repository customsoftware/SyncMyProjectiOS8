//
//  CCProjectSwitchTableViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/5/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Task+CategoryTask.h"
#import "CCAppDelegate.h"
#import "WorkTime.h"

@interface CCProjectSwitchTableViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *projectFRC;
@property (strong, nonatomic) Project *selectedProject;
@property (strong, nonatomic) WorkTime *currentTimer;
@property (strong, nonatomic) Task *currentTask;

@end
