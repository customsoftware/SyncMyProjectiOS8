//
//  CCGeneralCloser.h
//  ProjectFolio
//
//  Created by Ken Cluff on 9/6/12.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "CCMasterViewController.h"
#import "CCiPhoneMasterViewController.h"

@interface CCGeneralCloser : UIViewController
@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchedResultsController *eventFRC;

-(void)setMessage;
-(void)billEvents;
-(CCGeneralCloser *)initWithLastWeek;
-(CCGeneralCloser *)initForYesterday;
-(CCGeneralCloser *)initForAll;

@end
