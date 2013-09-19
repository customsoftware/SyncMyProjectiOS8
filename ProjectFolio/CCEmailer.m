//
//  CCEmailer.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/25/12.
//  This handles all of the email tasks for Project Folio
//

#import "CCEmailer.h"

@interface CCEmailer ()

@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSArray *attachments;
@end

@implementation CCEmailer

-(void)addImageAttachments:(NSArray *)images{
    int x = 1;
    for (NSData * attachment in images) {
        NSString *fileNameString = [NSString stringWithFormat:@"Photo %d", x];
        [self.mailComposer addAttachmentData:attachment mimeType:@"image/jpeg" fileName:fileNameString];
        x++;
    }
}

-(void)addFileAttachements:(NSArray *)files{
    for (NSString * attachment in files) {
        NSData *attachedData = [NSData dataWithContentsOfFile:attachment];
        [self.mailComposer addAttachmentData:attachedData mimeType:@"text/plain" fileName:[attachment lastPathComponent]];
    }
}

-(void)sendEmail{
    self.mailComposer = [[MFMailComposeViewController alloc] init];
    self.mailComposer.mailComposeDelegate = self;
    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
    [self.mailComposer setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self.mailComposer setSubject:self.subjectLine];
    [self.mailComposer setMessageBody:self.messageText isHTML:[self.useHTML boolValue]];
    if (self.addressee != nil) {
        [self.mailComposer setToRecipients:[[NSArray alloc] initWithObjects:self.addressee, nil]];
    }

}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (error != nil) {
        [self.emailDelegate didFinishWithError:error];
    } else {
        [self.emailDelegate didFinishWithResult:result];
    }
}

#pragma mark - Lazy Getters
-(NSUserDefaults *)defaults{
    if (_defaults == nil) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

-(NSString *)addressee{
    if (_addressee == nil) {
        _addressee = [[NSString alloc] initWithFormat:@"%@", [self.defaults objectForKey:kDefaultEmail]];
    }
    return _addressee;
}

- (NSNumber *)useHTML{
    if (_useHTML == nil) {
        _useHTML = [NSNumber numberWithBool:YES];
    }
    return _useHTML;
}
@end
