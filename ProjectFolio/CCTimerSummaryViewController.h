//
//  CCTimerSummaryViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/14/12.
//
//

#import <UIKit/UIKit.h>
#import "WorkTime.h"
#import "Project.h"
#import "CCEmailer.h"
#import "CCAppDelegate.h"
#import "CCProjectTaskDelegate.h"
#import "CCTimeViewController.h"

@interface CCTimerSummaryViewController : UIViewController<CCTimeSelector,CCEmailDelegate,MFMailComposeViewControllerDelegate,UIPrintInteractionControllerDelegate,UIActionSheetDelegate,NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *totalProjectTime;
@property (strong, nonatomic) IBOutlet UILabel *billedTime;
@property (strong, nonatomic) IBOutlet UILabel *unbilledTime;
@property (strong, nonatomic) IBOutlet UISwitch *markBilled;
@property (strong, nonatomic) IBOutlet UISegmentedControl *outPut;
@property (strong, nonatomic) IBOutlet UILabel *reportableTime;
@property (strong, nonatomic) IBOutlet UILabel *billRate;
@property (strong, nonatomic) IBOutlet UILabel *billingAmount;
@property (strong, nonatomic) IBOutlet UILabel *remainingTime;
@property (strong, nonatomic) IBOutlet UILabel *remainingBudget;
@property (strong, nonatomic) WorkTime *time;
@property double hoursToBeBilled;
@property (weak, nonatomic) id<CCProjectTaskDelegate>projectDelegate;

-(IBAction)setFilterRange:(UISegmentedControl *)sender;
-(IBAction)showDetails:(UISegmentedControl *)sender;
-(NSInteger)getSelectedSegment;
@end
