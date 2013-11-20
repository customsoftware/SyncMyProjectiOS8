//
//  RatingReminder.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 9/18/13.
//
//

#import <Foundation/Foundation.h>

@interface RatingReminder : NSObject

- (id)initWithNumberOfRuns:(NSInteger)runCount;
- (void)startTimer;

@end
