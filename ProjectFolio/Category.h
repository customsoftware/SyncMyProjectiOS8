//
//  Category.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Task;

@interface Category : NSManagedObject

@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) Task *catTask;

@end
