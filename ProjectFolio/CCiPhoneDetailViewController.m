//
//  CCiPhoneDetailViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 11/28/12.
//
//

#import "CCiPhoneDetailViewController.h"
#import "CCPrintNotesRender.h"
#import "CCSettingsControl.h"

#define kShowProjects @"neverShowProjects"
#define kFontNameKey @"font"
#define kFontSize @"fontSize"
#define kBlueNameKey @"bluebalance"
#define kRedNameKey @"redbalance"
#define kGreenNameKey @"greenbalance"
#define kSaturation @"saturation"

@interface CCiPhoneDetailViewController () <UITextViewDelegate,UIPrintInteractionControllerDelegate>
- (void)configureView;
@property BOOL canUseCalendar;
@property (weak, nonatomic) CCAuxSettingsViewController *settings;
@property (strong, nonatomic) CCTaskSummaryViewController *summaryController;
@property (strong, nonatomic) CCEmailer *emailer;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) UIMenuItem *longPressMenu;
@property NSInteger lastButton;
@property (strong, nonatomic) CCSettingsControl *sysSettings;

@end

@implementation CCiPhoneDetailViewController

#pragma mark - Managing the detail item
- (BOOL)checkIsDeviceVersionHigherThanRequiredVersion:(NSString *)requiredVersion
{
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:requiredVersion options:NSNumericSearch] != NSOrderedAscending)
    {
        return YES;
    }
    
    return NO;
}

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    [self.navigationController popViewControllerAnimated:YES];
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
    self.projectNotes.backgroundColor = newColor;
}

- (void)configureView
{
    self.projectNotes.delegate = self;
    self.projectNotes.text = self.project.projectNotes;
    CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    if([self checkIsDeviceVersionHigherThanRequiredVersion:@"6.0"]) {
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
    self.showTimers.enabled = [self.sysSettings isTimeAuthorized];
    self.showTaskChart.enabled = [self.sysSettings isTimeAuthorized];
    self.showDeliverables.enabled = [self.sysSettings isExpenseAuthorized];
}

#pragma mark - Popover Controls
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
    [self.projectNotes resignFirstResponder];
}

-(IBAction)showTimePopover:(id)sender{
    self.settings = nil;
    self.calendar = nil;
    self.deliverable = nil;
    self.time = [self.storyboard instantiateViewControllerWithIdentifier:@"timerSummeryController"];
    self.time.projectDelegate = self;
    [self.navigationController pushViewController:self.time animated:YES];
    
}

-(IBAction)showDeliverablePopover:(id)sender{
    self.settings = nil;
    self.time = nil;
    self.calendar = nil;
    self.deliverable = [self.storyboard instantiateViewControllerWithIdentifier:@"expensesView"];
    self.deliverable.project = self.project;
    [self.navigationController pushViewController:self.deliverable animated:YES];
}

-(IBAction)showCalendarPopover:(id)sender{
    if (self.canUseCalendar) {
        self.settings = nil;
        self.deliverable = nil;
        self.time = nil;
        self.calendar = [self.storyboard instantiateViewControllerWithIdentifier:@"calendar"];
        self.calendar.project = self.project;
        [self.navigationController pushViewController:self.calendar animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning" message:@"You must grant access to your calendar for Project Folio to use it" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}

-(IBAction)showTaskChart:(UIBarButtonItem *)sender{
    /*if (self.popover != nil) {
        [self.popover dismissPopoverAnimated:YES];
    }*/
    [self releasePopovers];
    self.summaryController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskTimeLine"];
    self.summaryController.summaryDelegate = self;
    self.summaryController.aProject = [self getActiveProject];
    self.summaryController.modalPresentationStyle = UIModalPresentationPageSheet;
    self.summaryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:self.summaryController animated:YES completion:nil];
    self.summaryController.summaryDelegate = self;
}

-(IBAction)sendNotes:(UIBarButtonItem *)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send Notes", @"Contact Developer", nil];
    actionSheet.tag = 0;
    [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    [self.projectNotes resignFirstResponder];
}

-(IBAction)showSettings:(UIBarButtonItem *)sender{
    self.settings = [self.storyboard instantiateViewControllerWithIdentifier:@"settingsMain"];
    [self.navigationController pushViewController:self.settings animated:YES];
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self releasePopovers];
}

-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController{
    return YES;
}

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
                Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
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

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    self.lastButton = buttonIndex;
    if (actionSheet.tag == 0) {
        if (buttonIndex == 0) {
            // Present action sheet to sent notes
            UIActionSheet *actionSheet = [[ UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email Notes", @"Print Notes", nil];
            actionSheet.tag = 1;
            [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
            
        } else if (buttonIndex == 1) {
            self.emailer.subjectLine = @"Contact Developer";
            self.emailer.messageText = @"Enter your comments here.";
            self.emailer.emailDelegate = self;
            self.emailer.addressee = @"syncMyProject@ktcsoftware.com";
            self.emailer.useHTML = [NSNumber numberWithBool:YES];
            [self.emailer sendEmail];
            [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
        }
    } else if ( actionSheet.tag == 1) {
        if (buttonIndex == 0) {
            NSString *subject = nil;
            if (self.navigationController.navigationItem.title != nil) {
                subject = self.navigationController.navigationItem.title;
            } else {
                subject = self.navigationItem.title;
            }
            self.emailer.subjectLine = subject;
            self.emailer.messageText = self.projectNotes.text;
            self.emailer.emailDelegate = self;
            self.emailer.useHTML = [NSNumber numberWithBool:YES];
            [self.emailer sendEmail];
            [self presentViewController:self.emailer.mailComposer animated:YES completion:nil];
        } else if (buttonIndex == 1){
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
            [pic presentAnimated:YES completionHandler:completionHandler];
        }
    }
}

-(void)releaseLogger{
    self.logger = nil;
}

#pragma mark - <UITextViewDelegate>
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSString *startingText = self.projectNotes.text;
    if ([startingText rangeOfString:@"Enter notes for "].length > 0) {
        self.projectNotes.text = @"";
    } else {
        self.projectNotes.text = startingText;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.projectNotes.text.length == 0) {
        self.projectNotes.text = [NSString stringWithFormat:@"Enter notes for %@ project here", self.project.projectName];
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

#pragma mark - Helpers
- (void)handleTap {
    [self.projectNotes resignFirstResponder];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UITapGestureRecognizer *navTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [navTap setNumberOfTapsRequired:2];
    [navTap setNumberOfTouchesRequired:1];
    [self.navigationController.navigationBar addGestureRecognizer:navTap];
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    self.project.projectNotes = self.projectNotes.text;
    [self.projectNotes resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Accessors
-(CCSettingsControl *)sysSettings{
    if (_sysSettings == nil) {
        _sysSettings = [[CCSettingsControl alloc] init];
    }
    return _sysSettings;
}

-(NSFetchedResultsController *)fetchedProjectsController{
    if (_fetchedProjectsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project"
                                                  inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        [fetchRequest setEntity:entity];
        NSSortDescriptor *activeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"active" ascending:NO];
        NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
        NSSortDescriptor *endDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateFinish" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects: activeDescriptor, completeDescriptor, endDateDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext] sectionNameKeyPath:nil cacheName:@"ProjectList"];
        
        _fetchedProjectsController = aFetchedResultsController;
    }
    return _fetchedProjectsController;
}

-(CCEmailer *)emailer{
    if (_emailer == nil) {
        _emailer = [[CCEmailer alloc] init];
    }
    return _emailer;
}
@end
