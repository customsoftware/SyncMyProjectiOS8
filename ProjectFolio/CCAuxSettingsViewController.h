//
//  CCAuxSettingsViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import <UIKit/UIKit.h>
#import "CCLocationController.h"
#import "CCErrorLogger.h"

typedef enum settingTableOptions {
    settingFontOption = 0,
    settingCalendarOption,
    settingCatgoryOption,
    settingTintOption,
    settingBGColorOption
} settingTableOptions;

typedef enum alertOptions {
    timingAlert = 1,
    expenseAlert
} alertOptions;

@interface CCAuxSettingsViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,CCLocationDelegate,CCLoggerDelegate>
-(IBAction)changeFontSize:(UIStepper *)sender;
-(IBAction)setHomeLocation:(UIButton *)sender;
-(IBAction)email:(UITextField *)sender;

-(void)releaseLogger;
-(void)locationError:(NSError *)error;
-(void)locationUpdate:(CLLocation *)location;

@end
