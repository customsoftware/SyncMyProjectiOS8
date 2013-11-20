//
//  CCLatestNewsViewController.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 8/3/13.
//
//

#import <UIKit/UIKit.h>
#import "CCPopoverControllerDelegate.h"

@interface CCLatestNewsViewController : UIViewController

@property (weak, nonatomic) id<CCPopoverControllerDelegate>popDelegate;

@end
