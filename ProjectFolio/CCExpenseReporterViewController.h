//
//  CCExpenseReporterViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Deliverables.h"
#import "WorkTime.h"

@interface CCExpenseReporterViewController : UIViewController

/*
Check for money budget
Add up all the unbilled expenses
    milage
    purchases
 
*/
@property (strong, nonatomic) NSArray *receiptList;

-(NSString *)getExpenseReportForProject:(Project *)project;
-(NSString *)getLocationOfPDFExpenseReportForProject:(Project *)project;

@end
