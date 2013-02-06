//
//  CCAuxSettingsViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import <UIKit/UIKit.h>
#import "CCMasterViewController.h"
#import "CCAuxFontListViewController.h"
#import "CCAppDelegate.h"
#import "CCLocationController.h"
#import <QuartzCore/QuartzCore.h>
#import "CCErrorLogger.h"
#import "CCAuxPriorityViewController.h"
#import "CCAuxCalendarSettingViewController.h"

@interface CCAuxSettingsViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,CCLocationDelegate,CCLoggerDelegate>
-(IBAction)changeFontSize:(UIStepper *)sender;
-(IBAction)setHomeLocation:(UIButton *)sender;
-(IBAction)tapHandler:(UITapGestureRecognizer *)sender;
-(IBAction)email:(UITextField *)sender;
-(IBAction)openFAQ:(UIButton *)sender;

-(void)releaseLogger;
-(void)locationError:(NSError *)error;
-(void)locationUpdate:(CLLocation *)location;

@property (weak, nonatomic) IBOutlet UIStepper *changeFontSize;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *colorPad;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UITextField *email;
@end
