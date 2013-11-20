//
//  CCIAPCards.m
//  CardFile
//
//  Created by Kenneth Cluff on 6/8/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import "CCIAPCards.h"

@implementation CCIAPCards

+ (CCIAPCards *)sharedInstance{
    static CCIAPCards *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *productIdentifiers = [NSSet setWithObjects:
                                     kExpenseFeatureKey,
                                     kTimerFeatureKey, nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)expensesPurchased{
    // Verify the receipt
    BOOL featureEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kExpenseFeatureKey];
    return featureEnabled;
}

- (BOOL)timerPurchased{
    // Verify the receipt
    BOOL featureEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kTimerFeatureKey];
    return featureEnabled;
}

@end
