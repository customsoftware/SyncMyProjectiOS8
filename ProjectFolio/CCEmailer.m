//
//  CCEmailer.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/25/12.
//  This handles all of the email tasks for Project Folio
//

#import "CCEmailer.h"
#define kDefaultEmail @"defaultEmail"

@interface CCEmailer ()

@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSArray *attachments;
@end

@implementation CCEmailer

@synthesize mailComposer = _mailComposer;
@synthesize defaults = _defaults;
@synthesize subjectLine = _subjectLine;
@synthesize messageText = _messageText;
@synthesize addressee = _addressee;
@synthesize emailDelegate = _emailDelegate;
@synthesize attachments = _attachments;

-(void)addImageAttachments:(NSArray *)images{
    for (NSData * attachment in images) {
        [self.mailComposer addAttachmentData:attachment mimeType:@"image/jpeg" fileName:@"Photo"];
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
    [self.mailComposer setMessageBody:self.messageText isHTML:YES];
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

-(void)viewDidUnload{
    self.defaults = nil;
    self.subjectLine = nil;
    self.messageText = nil;
    self.addressee = nil;
    self.emailDelegate = nil;
    self.mailComposer = nil;
    self.attachments = nil;
}

#pragma mark - Lazy Getters
-(NSUserDefaults *)defaults{
    if (_defaults == nil) {
        _defaults = [[NSUserDefaults alloc] init];
    }
    return _defaults;
}

-(NSString *)addressee{
    if (_addressee == nil) {
        _addressee = [[NSString alloc] initWithFormat:@"%@", [self.defaults objectForKey:kDefaultEmail]];
    }
    return _addressee;
}

@end
