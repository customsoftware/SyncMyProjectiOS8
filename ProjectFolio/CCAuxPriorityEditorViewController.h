//
//  CCAuxPriorityEditorViewController.h
//  SyncMyProject
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@protocol CCPriorityDetailDelegate <NSObject>

-(void)saveUpdatedDetail:(NSString *)newValue;
-(void)saveUpdatedColor:(NSString *)newValue;
-(NSString *)getDetailValue;
-(NSString *)getPriorityColor;

@end

@interface CCAuxPriorityEditorViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *priorityText;
@property (weak, nonatomic) id<CCPriorityDetailDelegate>priorityDelegate;

@end
