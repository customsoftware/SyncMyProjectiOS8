//
//  CCGeneralCloser.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/6/12.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "CCiPhoneMasterViewController.h"
#import "CCGeneralCloserProtocol.h"

@interface CCGeneralCloser : UIViewController
@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *eventFRC;
@property (strong, nonatomic) id<CCGeneralCloserProtocol>printDelegate;
@property (strong, nonatomic) NSString *messageString;

-(void)setMessage;
-(void)billEvents;
-(void)emailMessage;
-(CCGeneralCloser *)initWithLastWeek;
-(CCGeneralCloser *)initForYesterday;
-(CCGeneralCloser *)initForAll;

@end
