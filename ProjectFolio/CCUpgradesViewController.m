//
//  CCUpgradesViewController.m
//  SyncMyProject
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

- (IBAction)enableTiming:(UIButton *)sender;
- (IBAction)enableExpenses:(UIButton *)sender;
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
    self.products = [[NSArray alloc] init];
    self.priceFormatter = [[NSNumberFormatter alloc] init];
    [self.priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [self.priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    if ([[CCIAPCards sharedInstance] timerPurchased] && [[CCIAPCards sharedInstance] expensesPurchased]) {
        [self showFeatureAlreadyPurchased];
    } else {
        if ([SKPaymentQueue canMakePayments]) {
            
            [[CCIAPCards sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products){
                
            }];
        } else {
            
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)enableTiming:(UIButton *)sender {
    
}

- (IBAction)enableExpenses:(UIButton *)sender {
    
}

#pragma mark - <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == kDoRestore) {
        [[CCIAPCards sharedInstance] restoreCompletedTransactions];
    }
}

#pragma mark - Helper
- (IBAction)restorePurchase:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Purchase" message:@"This will restore your purchase of the iCloud Sync feature" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles: @"OK", nil];
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
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kiCloudSyncKey];
            *stop = YES;
        }
    }];
    //  UID: captain.moroni@ktcsoftware.com
    //  PWD: M0r0n!123
}

- (void)showFeatureAlreadyPurchased{

    
}

- (void)showFeaturePurchased{

    
}

@end
