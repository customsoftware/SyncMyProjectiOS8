//
//  CCBarObject.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/23/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "CCAppDelegate.h"
#import "barObjectProtocol.h"

@interface CCBarObject : UIView

@property (strong, nonatomic) NSArray *projectList;
@property (strong, nonatomic) NSFetchedResultsController *fetchedProjectsController;
@property (weak, nonatomic) id<barObjectProtocol>barDelegate;

@end
