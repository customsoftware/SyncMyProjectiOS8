//
//  CCNewProjectViewController.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/17/13.
//
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"

@interface CCNewProjectViewController : UIViewController

@property (weak, nonatomic) id<CCPopoverControllerDelegate>popoverDelegate;
@property (weak, nonatomic) IBOutlet UITextField *projectName;
@property (strong, nonatomic) NSString *passedProjectName;

@end
