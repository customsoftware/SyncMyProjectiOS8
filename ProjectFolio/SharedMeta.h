//
//  SharedMeta.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SharedMeta : NSManagedObject

@property (nonatomic, retain) NSNumber * boolValue;
@property (nonatomic, retain) NSNumber * intValue;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * keyValue;

@end
