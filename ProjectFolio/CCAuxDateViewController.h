//
//  CCAuxDateViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/1/12.
//
//

#import <UIKit/UIKit.h>
#import "CCSaveDate.h"

@interface CCAuxDateViewController : UIViewController

-(IBAction)newDate:(UIDatePicker *)sender;

@property (strong, nonatomic) IBOutlet UIDatePicker *projectDate;
@property (strong, nonatomic) NSDate *dateValue;
@property (strong, nonatomic) NSString *barCaption;
@property (weak, nonatomic) id<CCSaveDate> delegate;
@property (strong, nonatomic) NSDate *minimumDate;
@property (strong, nonatomic) NSDate *maximumDate;

@end
