//
//  CCProjectTaskReport.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 10/19/13.
//
//

#import "CCProjectTaskReport.h"

@implementation CCProjectTaskReport

+ (NSArray *) getTaskLevelReportForDateRange:(kRangeModes) rangeMode fromDate:(NSDate *)startDate {
    // The query we want to replace:
    /*
     SELECT MIN( w.start ) as startDate, p.projectName, @"        " as title, SUM( w.end - w.start ) as ElapseTime
        FROM Project p
            INNER JOIN WorkTime w ON p.projectID = w.projectID
       WHERE p.completed = 0
         AND p.active = 1
     GROUP BY p.projectName
     ORDER BY p.projectName, title, startDate
     UNION ALL
     SELECT MIN( w.start ) as startDate, p.projectName, t.title as title, SUM( w.end - w.start ) as ElapseTime
        FROM Project p
            INNER JOIN WorkTime w ON p.projectID = w.projectID
            INNER JOIN Task t ON t.projectID = t.projectID
       WHERE p.completed = 0
         AND p.active = 1
    GROUP BY p.projectName
    ORDER BY p.projectName, title, startDate
     
    */
}

@end
