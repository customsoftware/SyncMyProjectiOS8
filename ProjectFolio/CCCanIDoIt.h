//
//  CCCanIDoIt.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/8/12.
//
//

#import <Foundation/Foundation.h>
#import "Project.h"
#import "WorkTime.h"
#import "CoreData.h"

@interface CCCanIDoIt : NSObject
+(void)runAnalysisForProject:(Project *)project;
-(CCCanIDoIt *)initWithProject:(Project *)project;

@end
