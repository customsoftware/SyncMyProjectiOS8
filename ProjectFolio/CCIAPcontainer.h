//
//  CCIAPcontainer.h
//  CardFile
//
//  Created by Kenneth Cluff on 6/8/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import <Foundation/Foundation.h>

//UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;

//NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray *products);

@interface CCIAPcontainer : NSObject

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;

@end
