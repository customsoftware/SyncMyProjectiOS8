//
//  CCNullSortDescriptor.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/22/12.
//
//

#import <Foundation/Foundation.h>

@interface CCNullSortDescriptor : NSSortDescriptor

-(id)copyWithZone:(NSZone *)zone;
-(id)reversedSortDescriptor;
-(NSComparisonResult)compareObject:(id)object1 toObject:(id)object2;

@end
