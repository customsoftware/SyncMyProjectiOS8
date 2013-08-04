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
#import "CCUpgradesViewController.h"

@interface CCAuxSettingsViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,CCLocationDelegate,CCLoggerDelegate>
-(IBAction)changeFontSize:(UIStepper *)sender;
-(IBAction)setHomeLocation:(UIButton *)sender;
-(IBAction)tapHandler:(UITapGestureRecognizer *)sender;
-(IBAction)email:(UITextField *)sender;
-(IBAction)openFAQ:(UIButton *)sender;
-(IBAction)setTimer:(UISwitch *)sender;

-(void)releaseLogger;
-(void)locationError:(NSError *)error;
-(void)locationUpdate:(CLLocation *)location;

@end
