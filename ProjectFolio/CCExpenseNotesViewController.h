//
//  CCExpenseNotesViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/20/12.
//
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"
#import "Deliverables.h"
#import "Task.h"
#import "Project.h"
#import "CCAppDelegate.h"

@protocol CCNotesDelegate <NSObject>

-(void)releaseNotes;
-(NSString *)getNotes;
-(BOOL)isTaskClass;

@optional
-(Task *)getParentTask;

@end

@interface CCExpenseNotesViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *notes;
@property (strong, nonatomic) Deliverables *expense;
@property (strong, nonatomic) id<CCNotesDelegate>notesDelegate;

-(IBAction)closeNotes:(UIBarButtonItem *)sender;

@end
