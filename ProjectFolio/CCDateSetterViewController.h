//
//  CCDateSetterViewController.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"
#import "Project.h"
#import "CCAuxDateViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "CCAuxTaskCloneViewController.h"
#import "CCSaveDate.h"
#import "CCCanIDoIt.h"
#import "CCAuxDurationViewController.h"
#import "CCCategoryTaskViewController.h"

@class CCMasterViewController;

@interface CCDateSetterViewController : UIViewController<CCSaveDate,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate,ABPeoplePickerNavigationControllerDelegate,CCPopoverControllerDelegate,CCCategoryTaskDelegate>{
    UISegmentedControl *segmentedControl;
    NSUInteger selectedDate;
}

@property(strong, nonatomic) id<CCPopoverControllerDelegate>delegate;
@property (strong, nonatomic) ABPeoplePickerNavigationController *ownerController;
@property (strong, nonatomic) CCAuxDateViewController *dateController;

@property (strong, nonatomic) IBOutlet UITextField *projectName;
@property (strong, nonatomic) IBOutlet UITextField *hourlyRateField;
@property (strong, nonatomic) IBOutlet UITextField *projectCostBudget;
@property (strong, nonatomic) IBOutlet UITableView *settingsController;
@property (strong, nonatomic) IBOutlet UISwitch *activeSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *completeSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *billableSwitch;
@property (strong, nonatomic) UIPopoverController *popControll;

@property (weak, nonatomic ) CCMasterViewController *parentController;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) Project *project;

-(IBAction)name:(UITextField *)sender;
-(IBAction)projectActive:(UISwitch *)sender;
-(IBAction)completeProject:(UISwitch *)sender;
-(IBAction)billableProject:(UISwitch *)sender;
-(IBAction)hourlyRate:(UITextField *)sender;
-(IBAction)projectCostBudget:(UITextField *)sender;
-(IBAction)utilities:(UISegmentedControl *)sender;

-(Priority *)getCurrentCategory;
-(void)saveSelectedCategory:(Priority *)newCategory;


@end
