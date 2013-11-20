//
//  CCLocalData.m
//  CDHarness
//
//  Created by Kenneth Cluff on 2/12/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import "CCLocalData.h"
#define kCompanyID          @"4MAEKVPSTZ.com.customsoftware.projectfolio."
#define kUbiquityCtrName    @"com.customsoftware.projectfolio"
#define kAppStatus @"Status"
#define kiCloudToken @"Token"
#define kAppID @"synctask"
#define kStartupFinished @"Startup Finished"

@implementation CCLocalData

+(NSArray *)entities{
    NSArray *entityArray = @[@"Task", @"Project"];
    return entityArray;
}

+(NSString *)companyID{
    return kCompanyID;
}

+(NSString *)appID{
    return kAppID;
}

+(NSString *)dbFileName{
    return [NSString stringWithFormat:@"%@.sqlite", kAppID];
}

+(NSString *)ubiquityContainerID{
    NSString *retValue = [[NSString alloc] initWithFormat:@"%@%@", kCompanyID, kAppID];
    return retValue;
}

+(BOOL)isICloudAuthorized{
    NSLog(@"Here is where we check to see if iCloud purchase has been made");
    return YES;
}

-(void)reloadFetchedResults:(NSNotification *)notification{
    // Some code will eventually go here
}

-(void)kvStoreDidChange:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber * reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    if (reasonForChange) {
        reason = [reasonForChange integerValue];
        
        if (reason == NSUbiquitousKeyValueStoreServerChange ||
            reason == NSUbiquitousKeyValueStoreInitialSyncChange ) {
            NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
            for (NSString *iKey in changedKeys) {
                if ([iKey isEqualToString:kAppString]) {
                    // Send a notification out which the detail controller is listening for...
                    NSNotification *keyChange = [NSNotification notificationWithName:kAppString object:nil];
                    [[NSNotificationCenter defaultCenter] postNotification:keyChange];
                    /*UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Cloud Message" message:@"Cloud message updating status received" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];*/
                }
            }
        }
    }
}
@end
