//
//  CCTextEntryPopoverController.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"

@interface CCTextEntryPopoverController : UIViewController

@property(strong, nonatomic) id<CCPopoverControllerDelegate>delegate;

@property(strong, nonatomic) IBOutlet UITextField *textField;
@property(strong, nonatomic) NSString *projectName;

-(IBAction)cancelPressed:(id)sender;
-(IBAction)savePressed:(id)sender;

-(BOOL)shouldShowCancelButton;

@end
