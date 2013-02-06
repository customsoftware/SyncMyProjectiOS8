//
//  CCAuxDurationViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"

@interface CCAuxDurationViewController : UIViewController<UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *countDown;
@property (strong, nonatomic) id<CCPopoverControllerDelegate>durationDelegate;
@property (strong, nonatomic) NSNumber *spinnerValue;

-(IBAction)cancel:(UIBarButtonItem *)sender;
-(IBAction)save:(UIBarButtonItem *)sender;
@end
