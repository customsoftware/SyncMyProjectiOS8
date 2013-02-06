//
//  CCCategoryTaskViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/22/12.
//
//

#import <UIKit/UIKit.h>
#import "Priority.h"
#import "CCAppDelegate.h"

@protocol CCCategoryTaskDelegate <NSObject>

-(Priority *)getCurrentCategory;
-(void)saveSelectedCategory:(Priority *)newCategory;

@end

@interface CCCategoryTaskViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) id<CCCategoryTaskDelegate>categoryDelegate;

-(IBAction)cancelCategory:(id)sender;

@end
