//
//  CCIAPcontainer.m
//  CardFile
//
//  Created by Kenneth Cluff on 6/8/13.
//  Copyright (c) 2013 Kenneth Cluff. All rights reserved.
//

#import "CCIAPcontainer.h"
NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

@interface CCIAPcontainer () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (strong, nonatomic) SKProductsRequest *productRequest;
@property (strong, nonatomic) NSSet *productIdentifiers;
@property (strong, nonatomic) NSMutableSet *purchasedProductIdentifiers;

@end

@implementation CCIAPcontainer
RequestProductsCompletionHandler _completionHandler;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers{
    if (self = [super init]) {
        _productIdentifiers = productIdentifiers;
        
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString *productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
            }
        }
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

#pragma mark - Instance API
- (BOOL)productPurchased:(NSString *)productIdentifier{
    return [self.purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler{
    _completionHandler = [completionHandler copy];
    
    self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIdentifiers];
    self.productRequest.delegate = self;
    [self.productRequest start];
}

#pragma mark - <SKPaymentTransactionObserver>
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

#pragma mark - <SKProductsRequestDelegate>
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    self.productRequest = nil;
    NSArray *skProducts = response.products;
    for (SKProduct *skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    self.productRequest = nil;
    _completionHandler(NO, nil);
    _completionHandler = nil;
}

#pragma mark - Helpers
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

@end
