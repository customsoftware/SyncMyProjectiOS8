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
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) CCAuxDateViewController *dateController;
@property (strong, nonatomic) UIPopoverController *popControll;
@property (weak, nonatomic) id<CCPopoverControllerDelegate> popDelegate;
@property (weak, nonatomic) NSIndexPath *controllingIndex;
@property BOOL * isNew;


-(NSString *)getNotes;
-(BOOL)isTaskClass;

-(void)locationError:(NSError *)error;
-(void)locationUpdate:(CLLocation *)location;


@end
