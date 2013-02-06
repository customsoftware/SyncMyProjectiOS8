//
//  CCNullSortDescriptor.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/22/12.
//
//

#import "CCNullSortDescriptor.h"
#define NULL_OBJECT(a) ((a) == nil || [(a) isEqual:[NSNull null]])


@implementation CCNullSortDescriptor

- (id)copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithKey:[self key] ascending:[self ascending] selector:[self selector]];
}

- (id)reversedSortDescriptor
{
    return [[[self class] alloc] initWithKey:[self key] ascending:![self ascending] selector:[self selector]];
}

- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    if (NULL_OBJECT([object1 valueForKeyPath:[self key]]) ||
        [[object1 valueForKeyPath:[self key]] length] == 0)
        return ([self ascending] ? NSOrderedDescending : NSOrderedAscending);
    if (NULL_OBJECT([object2 valueForKeyPath:[self key]]) ||
        [[object2 valueForKeyPath:[self key]] length] == 0)
        return ([self ascending] ? NSOrderedAscending : NSOrderedDescending);
    return [super compareObject:object1 toObject:object2];
}


@end
