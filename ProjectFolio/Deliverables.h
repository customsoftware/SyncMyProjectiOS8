//
//  Deliverables.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Deliverables : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateExpensed;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSDate * datePaid;
@property (nonatomic, retain) NSNumber * expensed;
@property (nonatomic, retain) NSString * expenseUUID;
@property (nonatomic, retain) NSNumber * milage;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * paidTo;
@property (nonatomic, retain) NSString * pmtDescription;
@property (nonatomic, retain) NSData * receipt;
@property (nonatomic, retain) NSString * receiptPath;
@property (nonatomic, retain) Project *expenseProject;

@end
