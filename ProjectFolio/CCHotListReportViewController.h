//
//  CCHotListReportViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Task.h"

@interface CCHotListReportViewController : UIViewController

-(NSString *)getTaskListReportForProject:(Project *)project;

-(NSString *)getHotListReportForStatus:(NSInteger)pointer;

-(NSString *)getLocationOfPDFTaskListReportForProject:(Project *)project;


@end
