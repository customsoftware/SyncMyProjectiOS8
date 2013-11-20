//
//  CCSettingsControl.m
//  SyncMyProject
//
//  Created by Ken Cluff on 11/30/12.
//
//

#import "CCSettingsControl.h"
#import "CCIAPCards.h"

#define kAuthTimeKey        @"authorizeTimeKey"
#define kAuthExpenseKey     @"authorizeExpenseKey"


@interface CCSettingsControl ()

@property (strong, nonatomic) NSUserDefaults *defaults;

@end


@implementation CCSettingsControl

-(BOOL)isICloudAuthorized{
    return YES;
}

#pragma mark - In-App purchase API
-(BOOL)isTimeAuthorized{
    return YES;
//    return [self.defaults boolForKey:kAuthTimeKey];
}

-(BOOL)isExpenseAuthorized{
    return YES;
//    return [self.defaults boolForKey:kAuthExpenseKey];
}

- (void)authorizeTime {
    
    [self.defaults setBool:YES forKey:kAuthTimeKey];
}

- (void)authorizeExpenses {
    [self.defaults setBool:YES forKey:kAuthExpenseKey];
}

- (void)deAuthorizeTime {
    [self.defaults setBool:NO forKey:kAuthTimeKey];
}

- (void)deAuthorizeExpenses {
    [self.defaults setBool:NO forKey:kAuthExpenseKey];
}

#pragma mark - Public API
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

#pragma mark - Accessors
- (NSUserDefaults *)defaults {
    if (!_defaults) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

@end
