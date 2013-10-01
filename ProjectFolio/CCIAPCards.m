//
//  CCIAPCards.m
//  CardFile
//
//  Created by Kenneth Cluff on 6/8/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import "CCIAPCards.h"

#define sharedSecret        @"a09000753fb445549bfcb844a5f3b424"

@implementation CCIAPCards

+ (CCIAPCards *)sharedInstance{
    static CCIAPCards *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *productIdentifiers = [NSSet setWithObjects:
                                     @"com.customsoftware.ProjectFolio.iCloudSync",
                                     @"com.customsoftware.ProjectFolio.test", nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)featurePurchased{
    // Verify the receipt
    BOOL iCloudSyncEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kiCloudSyncKey];
    return iCloudSyncEnabled;
}

@end
