//
//  RatingReminder.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 9/18/13.
//
//

/*
 This reminder works on letting a given number of launches pass then posting a reminder.
 This will repeat until they say "never again" or until they post a rating
*/

#import "RatingReminder.h"

#define kRateMeNow  0
#define kRemindMe   1
#define kNeverAgain 2
#define kAppStore   @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id="
#define kRatingKey  @"RatingReminderKey"

@interface RatingReminder () <UIAlertViewDelegate>

@property (strong, nonatomic) NSString *appName;
@property (strong, nonatomic) NSString *appID;
@property (nonatomic) NSInteger appRunCount;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) int runCount;

@end

@implementation RatingReminder

- (id)initWithNumberOfRuns:(NSInteger)runCount {
    self = [super init];
    
    if (self) {
        if (runCount > 0) {
            // This is how many times the app runs before a reminder pops up
            self.appRunCount = [[NSUserDefaults standardUserDefaults] integerForKey:kRatingCounterReferenceKey];
        }
        self.runCount = runCount;
        runCount++;
        [[NSUserDefaults standardUserDefaults] setInteger:runCount forKey:kRatingCounterKey];
    }
    
    return self;
}

- (void)startTimer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:15];
        self.timer = [[NSTimer alloc] initWithFireDate:fireDate interval:0 target:self selector:@selector(askForARating:) userInfo:nil repeats:NO];
    });
}

- (void)rateMe {
    NSString *appString = [NSString stringWithFormat:@"%@%@", kAppStore, kAppleID];
    NSURL *ratingsURL = [[NSURL alloc] initWithString:appString];
    [[UIApplication sharedApplication] openURL:ratingsURL];
    [[NSUserDefaults standardUserDefaults] setInteger:kNeverAgain forKey:kRatingKey];
}

- (void)askForARating:(NSTimer *)timer {
    // If the run count exceeds the appRunCount, it's time to pop the reminder
    if (self.appRunCount < self.runCount) {
        //                int reminderStatus = [[NSUserDefaults standardUserDefaults] integerForKey:kRatingKey];
        //                if ( reminderStatus < kNeverAgain) {
//        [self startTimer];
        //                }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *alertTitle = kAppName;
            NSString *alertText = [NSString stringWithFormat:@"Are you enjoying %@? Would you like something do work differently? Please let me know by giving %@ a review.", kAppName, kAppName];
            NSString *canxTitle = @"Please don't ask again";
            NSString *laterTitle = @"Remind me later";
            NSString *nowTitle = @"Rate Now";
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertText delegate:self cancelButtonTitle:canxTitle otherButtonTitles:laterTitle, nowTitle, nil];
            [alert show];
        });
        
    }

}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
//    [self resetStartCounter];
    switch (buttonIndex) {
        case kRateMeNow:
            [self rateMe];
            break;
            
        case kRemindMe:
            // Do nothing
            break;
            
        case kNeverAgain:
            [[NSUserDefaults standardUserDefaults] setInteger:kNeverAgain forKey:kRatingKey];
            break;
            
        default:
            break;
    }
}

#pragma mark - Helpers
- (void)resetStartCounter {
    [[NSUserDefaults standardUserDefaults] setInteger:self.appRunCount * 1.5 forKey:kRatingCounterReferenceKey];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kRatingCounterKey];
}

@end
