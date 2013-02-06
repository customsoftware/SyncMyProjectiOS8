//
//  CCLocalNotification.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CCLocalNotification : UILocalNotification

-(UILocalNotification *)setAlert:(NSString *)message caption:(NSString *)caption alertDate:(NSDate *)alertDate;

-(UILocalNotification *)setRepeatingAlert:(NSString *)message caption:(NSString *)caption alertDate:(NSDate *)alertDate repeatInterval:(NSCalendarUnit)interval;

@end
