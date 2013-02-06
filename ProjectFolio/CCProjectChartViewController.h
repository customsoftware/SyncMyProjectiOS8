//
//  CCProjectChartViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/22/12.
//
//

#import <UIKit/UIKit.h>
#import "CCModalViewDelegate.h"
#import "CCMasterViewController.h"
#import "CCAppDelegate.h"
#import "CCBarObject.h"
#import "barObjectProtocol.h"

@interface CCProjectChartViewController : UIViewController<barObjectProtocol>

@property (strong, nonatomic) UIViewController *delegate;
@property (strong, nonatomic) IBOutlet CCBarObject *chartView;

-(IBAction)closeChart:(id)sender;
-(UIInterfaceOrientation)getDeviceOrientation;

@end
