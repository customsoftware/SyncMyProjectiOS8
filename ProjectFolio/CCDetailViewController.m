//
//  CCDetailViewController.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCDetailViewController.h"
#import "CCErrorLogger.h"
#import "CCProjectTaskDelegate.h"
#import "CCTaskSummaryViewController.h"
#import "CCAuxSettingsViewController.h"
#import "CCPrintNotesRender.h"
#import "iCloudStarterProtocol.h"
#import "CCSettingsControl.h"
#import "CCIAPcontainer.h"

#define kAppStore   @"https://itunes.apple.com/us/app/syncmyproject-time-expense/id728772576?ls=1&mt=8"

@interface CCDetailViewController () <UITextViewDelegate,CCPopoverControllerDelegate,SKStoreProductViewControllerDelegate,iCloudStarterProtocol>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@property BOOL canUseCalendar;
@property (strong, nonatomic) CCGeneralCloser *closer;
@property (strong, nonatomic) CCAuxSettingsViewController *settings;
@property (strong, nonatomic) CCTaskSummaryViewController *summaryController;
@property (strong, nonatomic) CCSettingsControl *sysSettings;
@property (strong, nonatomic) CCEmailer *emailer;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) UIMenuItem *longPressMenu;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property NSInteger lastButton;
@property (strong, nonatomic) UISwipeGestureRecognizer *detailShow;
@property (strong, nonatomic) SKStoreProductViewController *storeController;
@property (nonatomic) BOOL inICloudMode;
@property (weak, nonatomic) IBOutlet UIButton *anchorButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendingNotes;
-(IBAction)showHelp:(UIButton *)sender;
-(IBAction)sendNotes:(UIBarButtonItem *)sender;

@end

@implementation CCDetailViewController
@synthesize emailer = _emailer;

#pragma mark - Managing the detail item
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

-(void)setFontForDisplay{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    // NSLog(@"Font: %@", fontFamily);
    NSString *nullString = [[NSString alloc] initWithFormat:@"%@", nil];
    if ([fontFamily isEqualToString:nullString]) {
        fontFamily = @"Optima";
    }
    CGFloat fontSize = [defaults integerForKey:kFontSize];
    if (fontSize < 16) {
        fontSize = 16;
    }
    UIFont *displayFont = [UIFont fontWithName:fontFamily size:fontSize];
    self.projectNotes.font = displayFont;
}

-(void)setDisplayBackGroundColor{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat alpha = [defaults floatForKey:kSaturation];
    CGFloat red = [defaults floatForKey:kRedNameKey];
    CGFloat blue = [defaults floatForKey:kBlueNameKey];
    CGFloat green = [defaults floatForKey:kGreenNameKey];
    UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    //self.projectNotes.backgroundColor = newColor;
    self.view.backgroundColor = newColor;
}

- (void)configureView
{
    self.projectNotes.text = self.project.projectNotes;
    self.projectNotes.delegate = self;
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([application checkIsDeviceVersionHigherThanRequiredVersion:@"6.0"]) {
        [application.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
            if (granted){
                //---- codes here when user allow your app to access theirs' calendar.
                self.canUseCalendar = YES;
            }else
            {
                //----- codes here when user NOT allow your app to access the calendar.
                self.canUseCalendar = NO;
            }
        }];
    } else {
        self.canUseCalendar = YES;
    }
    [self setFontForDisplay];
    [self setDisplayBackGroundColor];
}

-(void)enableControls{
    if (self.project != nil) {
        self.showDeliverables.enabled = [self.sysSettings isExpenseAuthorized];
        self.showCalendar.enabled = YES;
        self.showTimers.enabled = [self.sysSettings isTimeAuthorized];
        self.showTaskChart.enabled = [self.sysSettings isTimeAuthorized];
        self.showChart.enabled = [self.sysSettings isTimeAuthorized];
    }
}

#pragma mark - Popover Controls
-(void)savePopoverData{
    // Just to keep the compiler happy
}

-(void)cancelSummaryChart{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(Project *)getControllingProject{
    return [self getActiveProject];
}

-(Project *)getActiveProject{
    return self.project;
}

-(void)dismissModalView:(UIView *)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)releasePopovers{
    self.popover = nil;
    self.calendar = nil;
    self.deliverable = nil;
    self.time = nil;
    self.settings = nil;
    [self.projectNotes resignFirstResponder];
}

-(IBAction)showTimePopover:(id)sender{
    if (self.project) {
        if (self.popover != nil) {
            [self.popover dismissPopoverAnimated:YES];
        }
        if (self.time == nil) {
            [self releasePopovers];
            [self performSegueWithIdentifier:@"time" sender:sender];
        } else {
            self.time = nil;
        }
    }
}

-(IBAction)showDeliverablePopover:(id)sender{
    if (self.project) {
        if (self.popover != nil) {
            [self.popover dismissPopoverAnimated:YES];
        }
        if (self.deliverable == nil) {
            [self releasePopovers];
            [self performSegueWithIdentifier:@"deliverable" sender:sender];
        } else {
            self.deliverable = nil;
        }
    }
}

-(IBAction)showCalendarPopover:(id)sender{
    if (self.canUseCalendar) {
        if (self.project) {
            if (self.popover != nil) {
                [self.popover dismissPopoverAnimated:YES];
            }
            if (self.calendar == nil) {
                [self releasePopovers];
                [self performSegueWithIdentifier:@"calendar" sender:sender];
            } else {
                self.calendar = nil;
            }
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning" message:@"You must grant access to your calendar for Project Folio to use it" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

-(IBAction)showChart:(UIBarButtonItem *)sender{
    if (self.popover != nil) {
        [self.popover dismissPopoverAnimated:YES];
    }
    [self releasePopovers];
    self.projectChart = [[CCProjectChartViewController alloc] initWithNibName:@"CCProjectChartViewController" bundle:nil];
    self.projectChart.modalPresentationStyle = UIModalPresentationFullScreen;
    self.projectChart.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.projectChart.delegate = self;
    [self.navigationController presentViewController:self.projectChart animated:YES completion:nil];
}

-(IBAction)showTaskChart:(UIBarButtonItem *)sender{
    if (self.popover != nil) {
        [self.popover dismissPopoverAnimated:YES];
    }
    [self releasePopovers];
    self.summaryController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskTimeLine"];
    self.summaryController.summaryDelegate = self;
    self.summaryController.aProject = [self getActiveProject];
    self.summaryController.modalPresentationStyle = UIModalPresentationFormSheet;
    self.summaryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:self.summaryController animated:YES completion:nil];
    self.summaryController.summaryDelegate = self;
}

-(IBAction)sendNotes:(UIBarButtonItem *)sender{
    UIActionSheet *actionSheet = [[ UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send Notes", @"Contact Developer", @"Close Projects", nil];
    actionSheet.tag = topSheet;
    [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

-(IBAction)showSettings:(UIBarButtonItem *)sender{
    if (self.popover != nil) {
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.settings == nil) {
        [self releasePopovers];
        [self performSegueWithIdentifier:@"projectSettings" sender:sender];
    } else {
        self.settings = nil;
    }
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self releasePopovers];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    self.popover = [(UIStoryboardPopoverSegue *)segue popoverController];
    self.popover.delegate = self;
    
    if ([[segue identifier] isEqualToString:@"projectSettings"]){
        UINavigationController *viewController = (UINavigationController *)self.popover.contentViewController;
        self.settings = (CCAuxSettingsViewController *)viewController.visibleViewController;
        
    }else if ([[segue identifier] isEqualToString:@"deliverable"]){
        UINavigationController *viewController = (UINavigationController *)self.popover.contentViewController;
        self.deliverable = (CCDeliverableViewController *)viewController.visibleViewController;
        self.deliverable.project = self.project;
        self.deliverable.popController = self.popover;
        
    } else if ([[segue identifier] isEqualToString:@"time"]){
        UINavigationController *viewController = (UINavigationController *)self.popover.contentViewController;
        self.time = (CCTimerSummaryViewController *)viewController.visibleViewController;
        self.time.projectDelegate = self;
        
    } else if ([[segue identifier] isEqualToString:@"calendar"]){
        UINavigationController *viewController = (UINavigationController *)self.popover.contentViewController;
        self.calendar = (CCCalendarViewController *)viewController.visibleViewController;
        self.calendar.project = self.project;
    } else if ([segue.identifier isEqualToString:@"popLatest"]) {
        CCLatestNewsViewController *latestController = (CCLatestNewsViewController *)self.popover.contentViewController;
        latestController.popDelegate = self;
    }
}

-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController{
    return YES;
}

-(IBAction)showHelp:(UIButton *)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ktcsoftware.com/pf/faq/faq.html"]];
}

- (void)showProjectDetails:(UIButton *)sender {
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"projectPopper"];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
    self.popover.delegate = self;
    CCDateSetterViewController *dateController = (CCDateSetterViewController *)navController.visibleViewController;
    dateController.project = self.project;
    dateController.popControll = self.popover;
    self.popover.popoverContentSize = CGSizeMake(540, 400);
// Show the popover
    [self.popover presentPopoverFromRect:self.anchorButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)printReport{
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.jobName = @"Close Projects";
    pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *notesFormatter = [[UIMarkupTextPrintFormatter alloc]
                                                  initWithMarkupText:self.closer.messageString];
    notesFormatter.startPage = 0;
    CCPrintNotesRender *renderer = [[CCPrintNotesRender alloc] init];
    renderer.headerString = @"Billable Hour Summary";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    renderer.fontName = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    renderer.fontSize = [defaults integerForKey:kFontSize];
    [renderer addPrintFormatter:notesFormatter startingAtPageAtIndex:0];
    pic.printPageRenderer = renderer;
    pic.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
}

#pragma mark - Custom Menu
-(void)handleCustomMenu{
    NSRange range = self.projectNotes.selectedRange;
    if (range.length > 0) {
        NSString *selectedString = [self.projectNotes.text substringWithRange:range];
        NSArray *componentsSeparatedByNewLines = [selectedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        float maxDisplay = 0;
        for (Task *ptask in self.project.projectTask) {
            if ([ptask.displayOrder floatValue] > maxDisplay) {
                maxDisplay = [ptask.displayOrder floatValue];
            }
        }
        
        maxDisplay = maxDisplay + 1;
        
        for (NSString * taskString in componentsSeparatedByNewLines) {
            if ([taskString length] > 0) {
                Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
                newTask.completed = [NSNumber numberWithBool:NO];
                if ([taskString length] > 35) {
                    newTask.notes = taskString;
                    newTask.title = [taskString substringToIndex:35];
                } else {
                    newTask.title = taskString;
                }
                newTask.displayOrder = [NSNumber numberWithFloat:maxDisplay];
                maxDisplay++;
                newTask.taskProject = self.project;
                newTask.level = [NSNumber numberWithInt:0];
                [self.project addProjectTaskObject:newTask];
                self.projectNotes.selectedTextRange = nil;
                NSString *addTaskNotification = [[NSString alloc] initWithFormat:@"%@", @"newTaskNotification"];
                NSNotification *newTaskNotification = [NSNotification notificationWithName:addTaskNotification object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:newTaskNotification];
            }
        }
    }
    [self.projectNotes resignFirstResponder];
}

#pragma mark - ActionSheet Functionality
-(void)didFinishWithResult:(MFMailComposeResult)result{
    if (self.lastButton == 1) {
        [self.logger removeErrorFile];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didFinishWithError:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendOutput{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Send Email" otherButtonTitles:@"Print Report", nil];
    sheet.tag = sendCloseOptionSheet;
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    self.lastButton = buttonIndex;
    if (actionSheet.tag == topSheet ) {
        if (buttonIndex == sendNotes) {
            // Present action sheet to sent notes
            UIActionSheet *actionSheet = [[ UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email Notes", @"Print Notes", nil];
            actionSheet.tag = sendOptionSheet;
            [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
            
        } else if (buttonIndex == contactDeveloper) {
            self.emailer.subjectLine = @"SyncMyProject Feedback";
            self.emailer.messageText = @"Enter your comments here.";
            self.emailer.emailDelegate = self;
            self.emailer.addressee = @"syncMyProject@ktcsoftware.com";
            self.emailer.useHTML = [NSNumber numberWithBool:YES];
            [self.emailer sendEmail];
            [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
        } else if (buttonIndex == closeProjects) {
            // Present action sheet to close projects
            if ([self.sysSettings isTimeAuthorized]) {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Report Time Spent on Projects" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Yesterday", @"This Week", @"All Active", nil];
                actionSheet.tag = closeOptionSheet;
                [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Premium Feature" message:@"This report is part of the time tracking upgrade." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
    } else if (actionSheet.tag == sendOptionSheet){
        // Put code here to email or print notes
        if (buttonIndex == emailNotes) {
            NSString *subject = nil;
            if (self.navigationController.navigationItem.title != nil) {
                subject = self.navigationController.navigationItem.title;
            } else {
                subject = self.navigationItem.title;
            }
            self.emailer.subjectLine = subject;
            self.emailer.addressee =  [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultEmail];
            self.emailer.messageText = self.projectNotes.text;
            self.emailer.emailDelegate = self;
            self.emailer.useHTML = [NSNumber numberWithBool:YES];
            [self.emailer sendEmail];
            [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
        } else if (buttonIndex == printNotes) {
            UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
            pic.delegate = self;
            
            UIPrintInfo *printInfo = [UIPrintInfo printInfo];
            printInfo.outputType = UIPrintInfoOutputGrayscale;
            printInfo.jobName = self.project.projectName;
            pic.printInfo = printInfo;
            
            UIPrintFormatter *notesFormatter = [self.projectNotes viewPrintFormatter];
            notesFormatter.startPage = 0;
            CCPrintNotesRender *renderer = [[CCPrintNotesRender alloc] init];
            renderer.headerString = [NSString stringWithFormat:@"Notes for %@ project", self.project.projectName];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            renderer.fontName = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
            renderer.fontSize = [defaults integerForKey:kFontSize];
            [renderer addPrintFormatter:notesFormatter startingAtPageAtIndex:0];
            pic.printPageRenderer = renderer;
            pic.showsPageRange = YES;
            
            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
            ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
                if (!completed && error) {
                    NSLog(@"Printing could not complete because of error: %@", error);
                }
            };
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [pic presentFromBarButtonItem:self.sendingNotes animated:YES completionHandler:completionHandler];
            } else {
                [pic presentAnimated:YES completionHandler:completionHandler];
            }
        }
    } else if (actionSheet.tag == closeOptionSheet){
        // Put code here that normally closed out projects
        switch (buttonIndex) {
            case closeAll:
                self.closer = [[CCGeneralCloser alloc] initForAllFor:self];
                [self.closer setMessage];
                break;
                
            case closeLastWeek:
                self.closer = [[CCGeneralCloser alloc] initWithLastWeekFor:self];
                [self.closer setMessage];
                break;
                
            case closeYesterday:
                self.closer = [[CCGeneralCloser alloc] initForYesterdayFor:self];
                [self.closer setMessage];
                break;
                
            default:
                break;
        }
    } else if ( actionSheet.tag == sendCloseOptionSheet ) {
        switch (buttonIndex) {
            case emailNotes:
                [self.closer emailMessage];
                [self.navigationController presentViewController:self.closer.mailComposer animated:YES completion:nil];
                break;
                
            case printNotes:
                [self printReport];
                break;
                
            default:
                break;
        }
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissModalView:viewController.view];
}


void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
    if (!completed && error)
        NSLog(@"FAILED! due to error in domain %@ with error code %ld",
              error.domain, (long)error.code);
};

-(void)releaseLogger{
    self.logger = nil;
}

#pragma mark - <MFMail>
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result == MFMailComposeResultCancelled) {
        // NSLog(@"Leave the timers intact");
    } else {
        [self.closer billEvents];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - <UITextViewDelegate>
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSString *startingText = self.projectNotes.text;
    if ([startingText rangeOfString:@"Enter notes for "].length > 0) {
        self.projectNotes.text = @"";
    }
}

/*-(void)textViewDidChange:(UITextView *)textView{
    self.project.projectNotes = textView.text;
}*/

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.project != nil ) {
        if ( self.projectNotes.text.length == 0) {
            self.projectNotes.text = [NSString stringWithFormat:@"Enter notes for %@ project here", self.project.projectName];
        } else {
            self.project.projectNotes = textView.text;
        }
    }
    [self.projectNotes resignFirstResponder];
}

#pragma mark - Handle Keyboard

-(void) handleKeyboardDidShow:(NSNotification *)paramNotification{
    NSValue *keyboardRectAsObject = [[paramNotification userInfo]
                                     objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect;
    
    [keyboardRectAsObject getValue:&keyboardRect];
    
    BOOL isPortrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    UIEdgeInsets contentInsets;
   
    if (isPortrait) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardRect.size.height, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardRect.size.width, 0.0);
    }
    
    self.projectNotes.contentInset = contentInsets;
}

-(void) handleKeyboardWillHide:(NSNotification *)paramNotification{
    self.projectNotes.contentInset = UIEdgeInsetsZero;
}

#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.inICloudMode = NO;
    // Do any additional setup after loading the view, typically from a nib.
    BOOL menuExists = NO;
    self.longPressMenu = [[UIMenuItem alloc] initWithTitle:@"Create Task" action:@selector(handleCustomMenu)];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    NSMutableArray *menuArray = [NSMutableArray arrayWithArray:menu.menuItems];
    for (UIMenuItem * menuItem in menuArray) {
        if ([menuItem.title isEqualToString:self.longPressMenu.title]) {
            menuExists = YES;
        }
    }
    if ( menuExists == NO) {
        [menuArray addObject:self.longPressMenu];
        menu.menuItems = [NSArray arrayWithArray:menuArray];
        [menu update];
    }
    
    self.swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showProjectDetails:)];
    [self.swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.navigationController.navigationBar addGestureRecognizer:self.swipeDown];
    [self configureView];
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [application registeriCloudDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableControls) name:kEnableExpense object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableControls) name:kEnableTime object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableControls) name:IAPHelperProductPurchasedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *fontChangeNotification = @"FontChangeNotification";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFontForDisplay) name:fontChangeNotification object:nil];
    NSString *colorChangeNotification = @"BackGroundColorChangeNotification";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDisplayBackGroundColor) name:colorChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self 
     selector:@selector(handleKeyboardDidShow:) 
     name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleKeyboardWillHide:) 
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BOOL showNews = [[NSUserDefaults standardUserDefaults] boolForKey:@"dontShowNewsAgain"];
    if (!showNews) {
        [self performSegueWithIdentifier:@"popLatest" sender:nil];
    }
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(IBAction)cancelPopover{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)respondToiCloudUpdate {
    self.projectNotes.text = @"";
    [self.indicator stopAnimating];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"iCloudStarted"];
    self.inICloudMode = NO;
}

#pragma mark - Split view
- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Show Projects", @"Show Projects");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Lazy Getters
- (CCSettingsControl *)sysSettings {
    if (!_sysSettings) {
        _sysSettings = [[CCSettingsControl alloc] init];
    }
    return _sysSettings;
}

-(NSManagedObjectContext *)managedObjectContext{
    return [[CoreData sharedModel:nil] managedObjectContext];
}

-(CCEmailer *)emailer{
    if (_emailer == nil) {
        _emailer = [[CCEmailer alloc] init];
    }
    return _emailer;
}

@end
