//
//  CCAuxPriorityEditorViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import <UIKit/UIKit.h>

@protocol CCPriorityDetailDelegate <NSObject>

-(void)saveUpdatedDetail:(NSString *)newValue;
-(NSString *)getDetailValue;

@end

@interface CCAuxPriorityEditorViewController : UIViewController

-(IBAction)updatePriority:(UITextField * )sender;

@property (strong, nonatomic) IBOutlet UITextField *priorityText;
@property (weak, nonatomic) id<CCPriorityDetailDelegate>priorityDelegate;

@end
