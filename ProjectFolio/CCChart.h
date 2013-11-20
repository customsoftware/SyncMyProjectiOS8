//
//  CCChart.h
//  SyncMyProject
//
//  Created by Ken Cluff on 9/28/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Task+CategoryTask.h"
#import "CCAppDelegate.h"

@protocol CCTaskChartDelegate <NSObject>

-(Project *)getControllingProject;

@end

@interface CCChart : UIView

-(CCChart *)initWithProject:(Project *)controllingProject andFrame:(CGRect)frame;

-(void)refreshDrawing;

@property (strong, nonatomic) Project *controllingProject;

@property (strong, nonatomic) NSString *saySomething;
@property (strong, nonatomic) id<CCTaskChartDelegate>taskChartDelegate;

@end
