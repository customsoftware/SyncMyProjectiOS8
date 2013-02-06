//
//  CCParentTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/10/12.
//
//

#import <UIKit/UIKit.h>
#import "Task.h"
#import "Project.h"
#import "CCAppDelegate.h"

@protocol ParentDelegate <NSObject>

-(void)saveParent;
-(void)cancelParent;

@end

@interface CCParentTaskViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) id<ParentDelegate>popDelegate;
@property (strong, nonatomic) Task *parentTask;
@property (strong, nonatomic) Task *activeTask;

@end
