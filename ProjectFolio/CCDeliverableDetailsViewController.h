//
//  CCDeliverableDetailsViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import <UIKit/UIKit.h>
#import "Deliverables.h"
#import "CCSaveDate.h"

@interface CCDeliverableDetailsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,CCSaveDate>

@property (strong, nonatomic) Deliverables *expense;
@property (strong, nonatomic) IBOutlet UITextField *payee;
@property (strong, nonatomic) IBOutlet UISwitch *expensed;
@property (strong, nonatomic) IBOutlet UITextView *notes;
@property (strong, nonatomic) IBOutlet UITextField *amountPaid;
@property (strong, nonatomic) IBOutlet UITextField *itemPurchased;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;

-(IBAction)expensed:(UISwitch *)sender;
-(IBAction)payee:(UITextField *)sender;
-(IBAction)amountPaid:(UITextField *)sender;
-(IBAction)itemPurchased:(UITextField *)sender;
-(IBAction)datePicker:(UIDatePicker *)sender;
-(void)saveDateValue:(NSDate *)dateValue;

@end
