//
//  CCExpenseDetailsViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import <UIKit/UIKit.h>
#import "Deliverables.h"
#import "CCSaveDate.h"
#import "CCAuxDateViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "CCPopoverControllerDelegate.h"
#import "CCExpenseNotesViewController.h"
#import "CCLocationController.h"

@interface CCExpenseDetailsViewController : UIViewController<CCSaveDate,UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIApplicationDelegate,CCLocationDelegate,CCNotesDelegate>

@property (strong, nonatomic) Deliverables *expense;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) CCAuxDateViewController *dateController;
@property (strong, nonatomic) UIPopoverController *popControll;
@property (weak, nonatomic) id<CCPopoverControllerDelegate> popDelegate;
@property (weak, nonatomic) NSIndexPath *controllingIndex;
@property BOOL * isNew;

@property (strong, nonatomic) IBOutlet UITextField *itemPurchased;
@property (strong, nonatomic) IBOutlet UITextField *paidTo;
@property (strong, nonatomic) IBOutlet UITextField *amountPaid;
@property (strong, nonatomic) IBOutlet UITextField *milage;
@property (strong, nonatomic) IBOutlet UISwitch *billed;
@property (strong, nonatomic) IBOutlet UIImageView *receipt;
@property (strong, nonatomic) IBOutlet UILabel *notes;
@property (strong, nonatomic) IBOutlet UISegmentedControl *utilityControll;

-(IBAction)itemPurchased:(UITextField *)sender;
-(IBAction)paidTo:(UITextField *)sender;
-(IBAction)amountPaid:(UITextField *)sender;
-(IBAction)billed:(UISwitch *)sender;
-(IBAction)utilities:(UISegmentedControl *)sender;
-(IBAction)milage:(UITextField *)sender;
-(IBAction)removePicture:(UIButton *)sender;
-(void)releaseNotes;
-(NSString *)getNotes;
-(BOOL)isTaskClass;

-(void)locationError:(NSError *)error;
-(void)locationUpdate:(CLLocation *)location;


@end
