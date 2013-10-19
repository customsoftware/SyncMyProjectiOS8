//
//  CCProjectTaskReport.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 10/19/13.
//
//

#import <Foundation/Foundation.h>

typedef enum kRangeModes{
    yesterdayMode = 0,
    lastWeekMode,
    lastMonthMode
} kRangeModes;

@interface CCProjectTaskReport : NSObject

+ (NSArray *) getTaskLevelReportForDateRange:(kRangeModes) rangeMode fromDate:(NSDate *)startDate;

@end
