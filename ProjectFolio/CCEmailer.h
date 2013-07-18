//
//  CCEmailer.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/25/12.
//
//

#import <MessageUI/MessageUI.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@protocol CCEmailDelegate <NSObject>

-(void)didFinishWithResult:(MFMailComposeResult)result;
-(void)didFinishWithError:(NSError *)error;

@end


@interface CCEmailer : UIViewController<MFMailComposeViewControllerDelegate>
/*
This will present the email dialog box and accept a subject line, email body and sending address
*/
@property (assign, nonatomic) id<CCEmailDelegate>emailDelegate;
@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) NSString *subjectLine;
@property (strong, nonatomic) NSString *messageText;
@property (strong, nonatomic) NSString *addressee;
@property (strong, nonatomic) NSNumber *useHTML;

-(void)sendEmail;
-(void)addImageAttachments:(NSArray *)images;
-(void)addFileAttachements:(NSArray *)files;

@end
