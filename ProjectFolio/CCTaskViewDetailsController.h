//
//  CCTaskViewDetailsController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/4/12.
//
//

#import <UIKit/UIKit.h>
#import "Task+CategoryTask.h"
#import "Priority.h"
#import "CCTaskDueDateViewController.h"
#import "CCAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>
#import <QuartzCore/QuartzCore.h>
#import "CCPopoverControllerDelegate.h"
#import "CCParentTaskViewController.h"
#import "CCAuxDurationViewController.h"
#import "CCExpenseNotesViewController.h"
#import "CCCategoryTaskViewController.h"

@interface CCTaskViewDetailsController : UIViewController<UITableViewDataSource,UITableViewDelegate,ABPeoplePickerNavigationControllerDelegate,MFMailComposeViewControllerDelegate,ParentDelegate,CCPopoverControllerDelegate,CCNotesDelegate,CCCategoryTaskDelegate>

@property (strong, nonatomic) Task *activeTask;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) NSString *notes;

@property (weak, nonatomic) id<CCPopoverControllerDelegate>taskDelegate;

-(IBAction)completeTask:(UISwitch *)sender;
-(IBAction)taskName:(UITextField *)sender;
-(IBAction)resetParams:(UIButton *)sender;
//-(IBAction)sendNotice:(UIBarButtonItem *)sender;
-(IBAction)showNotes:(UIButton *)sender;
-(void)releaseNotes;
-(NSString *)getNotes;
-(BOOL)isTaskClass;
-(Task *)getParentTask;


-(void)cancelPopover;
-(void)savePopoverData;
-(BOOL)shouldShowCancelButton;
-(void)saveSelectedCategory:(Priority *)newCategory;
-(Priority *)getCurrentCategory;

@end
