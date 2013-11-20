//
//  CCTaskSummaryViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/8/12.
//
//

#import <UIKit/UIKit.h>
#import "CCChart.h"
#import "Project.h"

@protocol CCTaskSummaryDelegate <NSObject>

-(void)cancelSummaryChart;
-(Project *)getControllingProject;

@end

@interface CCTaskSummaryViewController : UIViewController<CCTaskChartDelegate>

@property (strong, nonatomic) Project *aProject;
@property (strong, nonatomic) id<CCTaskSummaryDelegate>summaryDelegate;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;

-(IBAction)doneButton:(UIBarButtonItem *)sender;
-(void)updateViewContents;
-(Project *)getControllingProject;

@end
