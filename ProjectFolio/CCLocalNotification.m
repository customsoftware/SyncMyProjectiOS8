//
//  CCLocalNotification.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCLocalNotification.h"

@implementation CCLocalNotification

-(UILocalNotification *)setAlert:(NSString *)message caption:(NSString *)caption alertDate:(NSDate *)alertDate{
    UILocalNotification *localAlert = [[UILocalNotification alloc] init];
    localAlert.fireDate = alertDate;
    localAlert.timeZone = [NSTimeZone defaultTimeZone];
    localAlert.alertBody = [[NSString alloc] initWithFormat:@"%@", message];
    localAlert.alertAction = NSLocalizedString(caption, nil);
    localAlert.soundName = UILocalNotificationDefaultSoundName;
    
    return localAlert;
}

-(UILocalNotification *)setRepeatingAlert:(NSString *)message 
                                  caption:(NSString *)caption 
                                alertDate:(NSDate *)alertDate 
                           repeatInterval:(NSCalendarUnit)interval;
{
    UILocalNotification *localAlert = [[UILocalNotification alloc] init];
    localAlert.fireDate = alertDate;
    localAlert.timeZone = [NSTimeZone defaultTimeZone];
    localAlert.alertBody = [[NSString alloc] initWithFormat:@"%@", message];
    localAlert.alertAction = NSLocalizedString(caption, nil);
    localAlert.soundName = UILocalNotificationDefaultSoundName;
    localAlert.repeatInterval = interval;
    
    return localAlert;
}

@end
