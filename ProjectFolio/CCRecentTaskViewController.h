//
//  CCRecentTaskViewController.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 10/14/13.
//
//

#import <UIKit/UIKit.h>
#import "CCDetailViewController.h"

@interface CCRecentTaskViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) CCDetailViewController *projectDetailController;
@property (strong, nonatomic) CCProjectTimer *projectTimer;

@end
