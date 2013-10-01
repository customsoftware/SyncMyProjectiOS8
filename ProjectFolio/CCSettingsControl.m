//
//  CCSettingsControl.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/30/12.
//
//

#import "CCSettingsControl.h"
#import "CCIAPCards.h"

@implementation CCSettingsControl

-(BOOL)isICloudAuthorized{
    return [[CCIAPCards sharedInstance] featurePurchased];
//    return YES;
}


-(BOOL)saveString:(NSString *)stringValue atKey:(NSString *)keyName{
    BOOL retValue = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:stringValue forKey:keyName];
    [userDefaults synchronize];
    if ([self isICloudAuthorized]) {
        @try {
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            [store setObject:stringValue forKey:keyName];
            retValue = YES;
        }
        @catch (NSException *exception) {
            retValue = NO;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sync Failed" message:@"iCloud Sync failed. Only local setting saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }

    return retValue;
}

-(NSString *)recallStringAtKey:(NSString *)keyName{
    NSString *retValue = nil;
    
    if ([self isICloudAuthorized]) {
        @try {
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            retValue = (NSString *)[store objectForKey:keyName];
        }
        @catch (NSException *exception) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sync Failed" message:@"iCloud Sync failed. Local setting used" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            retValue = (NSString *)[userDefaults objectForKey:keyName];
        }
    } else {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        retValue = (NSString *)[userDefaults objectForKey:keyName];
    }
    return retValue;
}

-(BOOL)saveNumber:(NSNumber *)numberValue atKey:(NSString *)keyName{
    BOOL retValue = YES;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:numberValue forKey:keyName];
    [userDefaults synchronize];
    
    if ([self isICloudAuthorized]) {
        @try {
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            [store setObject:numberValue forKey:keyName];
            retValue = YES;
        }
        @catch (NSException *exception) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sync Failed" message:@"iCloud Sync failed. Only local setting saved." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    return retValue;
}

-(NSNumber *)recallNumberAtKey:(NSString *)keyName{
    NSNumber *retValue = nil;
    
    if ([self isICloudAuthorized]) {
        @try {
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            retValue = (NSNumber *)[store objectForKey:keyName];
        }
        @catch (NSException *exception) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sync Failed" message:@"iCloud Sync failed. Local setting used" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            retValue = (NSNumber *)[userDefaults objectForKey:keyName];
        }
    } else {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        retValue = (NSNumber *)[userDefaults objectForKey:keyName];
    }
    return retValue;
}

@end
