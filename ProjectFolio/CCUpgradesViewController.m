//
//  CCUpgradesViewController.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 8/3/13.
//
//

#import "CCUpgradesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CCIAPCards.h"
#define kCanxRestore 0
#define kDoRestore   1

@interface CCUpgradesViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *iCloudButton;

- (IBAction)iCloudSync:(UIButton *)sender;
- (IBAction)restorePurchase:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UITextView *iCloudText;
@property (strong, nonatomic) NSNumberFormatter *priceFormatter;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) NSArray *products;

@end

@implementation CCUpgradesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.priceFormatter = [[NSNumberFormatter alloc] init];
    [self.priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [self.priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    if ([[CCIAPCards sharedInstance] featurePurchased]) {
        [self showFeaturePurchased];
    } else {
        if ([SKPaymentQueue canMakePayments]) {
            self.iCloudText.text = @"This version of the app is limited to not sharing data with other devices. You must purchase the upgrade to share data with other devices on the same Apple account.";
            
            [[CCIAPCards sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products){
                if (success) {
                    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
                    [priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    
                    self.products = products;
                    SKProduct *product = (SKProduct *)self.products[0];
                    [priceFormatter setLocale:product.priceLocale];
                    NSString *productLabel = [NSString stringWithFormat:@"%@ - %@",
                                              product.localizedTitle,
                                              [priceFormatter stringFromNumber:product.price]
                                              ];
                    [self.iCloudButton setTitle:productLabel forState:UIControlStateNormal];
                    
                }
            }];
        } else {
            self.iCloudText.text = @"Currently, the data on this app can't be shared with other devices. You will need to enable iCloud sync on your device first.";
            self.iCloudButton.enabled = NO;
            self.refreshButton.enabled = NO;
            [self.iCloudButton setTitle:@"iCloud Sync Disabled" forState:UIControlStateDisabled];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iCloudSync:(UIButton *)sender {
    SKProduct *product = self.products[0];
    [[CCIAPCards sharedInstance] buyProduct:product];
}

#pragma mark - <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == kDoRestore) {
        [[CCIAPCards sharedInstance] restoreCompletedTransactions];
    }
}

#pragma mark - Helper
- (IBAction)restorePurchase:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Purchase" message:@"This will restore your purchase of the iClud Sync feature" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"OK", nil];
    [alert show];
}

- (void)showAlertText:(NSString *)message withTitle:(NSString *)title andButton:(NSString *)button{
    self.alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:button otherButtonTitles:nil];
    [self.alert show];
}

- (void)productPurchased:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct * product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [self showFeaturePurchased];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kiCloudSyncKey];
            *stop = YES;
        }
    }];
    //  UID: cmoroni@ktcsoftware.com
    //  PWD: M0r0n!123
}

- (void)showFeaturePurchased{
    self.iCloudButton.enabled = NO;
    self.refreshButton.enabled = NO;
    [self.iCloudButton setTitle:@"iCloud Sync Purchased" forState:UIControlStateDisabled];
    self.iCloudText.text = @"Thank you for your purchase. You will need to exit ProjectFolio completely, not just put it in the backrground and restart it for iCloud synchronization to start.";
}

@end
