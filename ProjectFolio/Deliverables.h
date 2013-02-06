//
//  Deliverables.h
//  ProjectFolio
//
//  Created by Ken Cluff on 11/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Deliverables : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSDate * dateExpensed;
@property (nonatomic, retain) NSDate * datePaid;
@property (nonatomic, retain) NSNumber * expensed;
@property (nonatomic, retain) NSNumber * milage;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * paidTo;
@property (nonatomic, retain) NSString * pmtDescription;
@property (nonatomic, retain) NSData * receipt;
@property (nonatomic, retain) Project *expenseProject;

@end
