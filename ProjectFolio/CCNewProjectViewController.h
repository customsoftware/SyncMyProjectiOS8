//
//  CCNewProjectViewController.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 4/5/13.
//
//

#import <UIKit/UIKit.h>
#import "Project+CategoryProject.h"
#import "CCPopoverControllerDelegate.h"


@interface CCNewProjectViewController : UIViewController

- (IBAction)saveData:(UIBarButtonItem *)sender;
- (IBAction)cancel:(UIBarButtonItem *)sender;
- (IBAction)projectName:(UITextField *)sender;

@property (weak, nonatomic) IBOutlet UITextField *projectName;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) id<CCPopoverControllerDelegate>popoverDelegate;

@end
