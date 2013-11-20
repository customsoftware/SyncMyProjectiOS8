//
//  CCTimeViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 8/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "WorkTime.h"
#import "CCProjectTimer.h"
#import "CCTimerDetailsViewController.h"
#import "CCAppDelegate.h"
#import "CCErrorLogger.h"

@protocol CCTimeSelector <NSObject>

-(NSInteger)getSelectedSegment;

@end

@interface CCTimeViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,CCLoggerDelegate>

@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) WorkTime *time;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (strong, nonatomic) IBOutlet UISegmentedControl *timeSelector;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDateFormatter *endDateFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) CCProjectTimer *parentTimer;
@property (strong, nonatomic) NSMutableArray *displayTimers;
@property (strong, nonatomic) CCTimerDetailsViewController *childController;
@property (strong, nonatomic) id<CCTimeSelector>timeSelectorDelegate;
@property BOOL startup;


-(IBAction)timeTypeSelected:(UISegmentedControl *)sender;
-(void)setTimerList:(UISegmentedControl *)sender;
-(void)releaseLogger;

@end
