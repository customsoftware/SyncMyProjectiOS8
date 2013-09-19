//
//  CCIAPCards.h
//  CardFile
//
//  Created by Kenneth Cluff on 6/8/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import "CCIAPcontainer.h"
#define kiCloudSyncKey @"heros_GTBB_UKZZ"

@interface CCIAPCards : CCIAPcontainer

+ (CCIAPCards *)sharedInstance;
- (void)restoreCompletedTransactions;
- (BOOL)featurePurchased;

@end
