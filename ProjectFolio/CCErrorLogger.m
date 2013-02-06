//
//  CCErrorLogger.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/26/12.
//
//

#import "CCErrorLogger.h"
#define kFileName @"crashlog.txt"
#define kErrorTitle @"System Alert"
#define kDirectoryError @"The application has encountered an error creating its error log. Please contact the developer for assistance and explain how you are currently using the application. Thank you."
#define kWriteError @"The application has encountered and error and is unable to log the error. Please contact the developer for assistance and explain how you are currently using the application. Thank you."

@interface CCErrorLogger  ()

@property (weak, nonatomic) id<CCLoggerDelegate> loggerDelegate;

@end

@implementation CCErrorLogger
@synthesize loggerDelegate = _loggerDelegate;

#pragma mark - Support Methods
-(NSString *)dataFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
            [self sendErrorAlertWithTitle:kErrorTitle andText:kDirectoryError];
        }
    }
    return [documentsDirectory stringByAppendingPathComponent:kFileName];
}

-(void)sendErrorAlertWithTitle:(NSString *)errorTitle andText:(NSString *)errorMessage{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)writeErrorNotification:(NSString *)errorText withTitle:(NSString *)title{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertAction = title;
    notification.alertBody = errorText;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = notification.applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark - API
-(CCErrorLogger *)initWithDelegate:(id)delegate{
    self = [super init];
    self.loggerDelegate = delegate;
    return self;
}

-(CCErrorLogger *)initWithError:(NSError *)error andDelegate:(id)delegate{
    self = [self initWithDelegate:delegate];
    [self writeErrorNotification:[error description] withTitle:[error localizedDescription]];
    NSString *errorLog = [self getErrorFile];
    if (![[error debugDescription] writeToFile:errorLog atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        [self sendErrorAlertWithTitle:kErrorTitle andText:kWriteError];
    }
    return self;
}

-(CCErrorLogger *)initWithErrorString:(NSString *)error andDelegate:(id)delegate{
    self = [self initWithDelegate:delegate];
    [self writeErrorNotification:error withTitle:@"Application Error"];
    // Write to the error log
    NSString *errorLog = [self getErrorFile];
    if (![error writeToFile:errorLog atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        [self sendErrorAlertWithTitle:kErrorTitle andText:kWriteError];
    }
    return self;
}

-(NSString *)getErrorFile{
    NSString *errorLog = [self dataFilePath];
    
    return errorLog;
}

-(void) releaseLogger{
    [self.loggerDelegate releaseLogger];
}

-(BOOL)removeErrorFile{
    BOOL retValue = YES;
    NSString *errorLog = [self getErrorFile];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    retValue = [fileMgr removeItemAtPath:errorLog error:&error];
    return retValue;
}

@end
