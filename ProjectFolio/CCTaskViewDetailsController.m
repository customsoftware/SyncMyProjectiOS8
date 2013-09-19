//
//  CCTaskViewDetailsController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 8/4/12.
//
//

#import "CCTaskViewDetailsController.h"
#import "CCPrintNotesRender.h"
#define kFontNameKey @"font"
#define kFontSize @"fontSize"
#define kDefaultEmail @"defaultEmail"


@interface CCTaskViewDetailsController ()
@property (strong, nonatomic) UITableViewCell *selectedCell;
@property (strong, nonatomic) CCTaskDueDateViewController *dueDateController;
@property (strong, nonatomic) CCParentTaskViewController *parentController;
@property (strong, nonatomic) ABPeoplePickerNavigationController *ownerController;
@property (strong, nonatomic) CCAuxDurationViewController *durationController;
@property (strong, nonatomic) CCExpenseNotesViewController *notesController;
@property (strong, nonatomic) CCCategoryTaskViewController *categoryController;
@property CGRect rect;
@property (weak, nonatomic) IBOutlet UITableView *taskParameters;
@property (weak, nonatomic) IBOutlet UITextField *taskTitle;
@property (weak, nonatomic) IBOutlet UISwitch *status;

@end

@implementation CCTaskViewDetailsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Actions and outlets
-(IBAction)showNotes:(UIButton *)sender{
    [self performSegueWithIdentifier:@"taskNotes" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"taskNotes"]) {
        UINavigationController *viewController = (UINavigationController *)segue.destinationViewController;
        self.notesController = (CCExpenseNotesViewController *)viewController.visibleViewController;
        self.notesController.navigationItem.title = [[NSString alloc] initWithFormat:@"Task: %@", self.taskTitle.text];
        self.notesController.notesDelegate = self;
    }
}

-(NSString *)getNotes{
    return self.activeTask.notes;
}

-(BOOL)isTaskClass{
    return YES;
}

-(Task *)getParentTask{
    return self.activeTask;
}

-(void)releaseNotes{
    self.activeTask.notes = self.notesController.notes.text;
    self.notes = self.activeTask.notes;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelParent{
    self.parentController.activeTask.superTask = nil;
    self.parentController.activeTask.level = [NSNumber numberWithInt:0];
    self.parentController.activeTask.displayOrder = [NSNumber numberWithInt:0];
    [self.activeTask removeSubTasksObject:self.parentController.activeTask];
}

-(void)saveParent{
    [self.taskDelegate savePopoverData];
}

-(void)cancelPopover{
    self.activeTask.duration = nil;
}

-(void)savePopoverData{
    self.activeTask.duration = self.durationController.spinnerValue;
}

-(void)cancelAddTask{
    [self.taskDelegate cancelPopover];
}

-(BOOL)shouldShowCancelButton{
    BOOL retValue = NO;
    if (self.selectedIndexPath == nil) {
        retValue = YES;
    }
    return retValue;
}

-(IBAction)taskName:(UITextField *)sender{
    self.activeTask.title = sender.text;
    [self.view endEditing:YES];
}

-(IBAction)completeTask:(UISwitch *)sender{
    self.activeTask.completed = [NSNumber numberWithBool:[sender isOn]];
    [self.taskParameters reloadData];
    [self.view endEditing:YES];
}

-(IBAction)resetParams:(UIButton *)sender{
    self.activeTask.assignedTo = nil;
    self.activeTask.assignedFirst = nil;
    self.activeTask.assignedLast = nil;
    self.activeTask.dueDate = nil;
    [self.taskParameters reloadData];
}

-(NSString *)getMailingAddress{
    NSString *retvalue;
    BOOL foundName = NO;
    CFErrorRef *error = nil;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    if (addressBook == nil) {
        retvalue = [[NSString alloc] initWithFormat:@"self"];
    } else {
        NSArray *arrayOfAllPeople = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSUInteger peopleCounter = 0;
        for (peopleCounter = 0; peopleCounter <[arrayOfAllPeople count]; peopleCounter++) {
            ABRecordRef person = (__bridge  ABRecordRef)[arrayOfAllPeople objectAtIndex:peopleCounter];
            NSString *name =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *lastName =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            if ([lastName isEqualToString:self.activeTask.assignedLast] && [name isEqualToString:self.activeTask.assignedFirst]) {
                ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
                if (emails == nil) {
                    retvalue = @"none";
                } else{
                    retvalue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, 0);
                    foundName = YES;
                    CFRelease(emails);
                }
            }
            if (foundName) {
                break;
            }
        }
        CFRelease(addressBook);
    }
    
    return  retvalue;
}

- (NSString *)printString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    NSString *taskString = nil;
    if (self.activeTask.dueDate == nil) {
        taskString = [[NSString alloc]
                      initWithFormat:@"You've been assigned the task of: %@. It has no due date yet.<p>",
                      self.activeTask.title];
    } else {
        taskString = [[NSString alloc]
                      initWithFormat:@"You've been assigned the task of: %@. It is due by %@<p>",
                      self.activeTask.title,
                      [formatter stringFromDate:self.activeTask.dueDate]];
    }
    
    taskString = [[NSString alloc] initWithFormat:@"%@", [self.activeTask getTaskNotesWithString:taskString]];
    
    NSArray *sentences = [taskString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableString *newString = [[NSMutableString alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    [newString appendString:[NSString stringWithFormat:@"<font face=&quot;%@&quot;>",fontFamily]];
    
    for (NSString *sentence in sentences) {
        [newString appendFormat:@"%@<p>", sentence];
    }
    [newString appendString: @"</font>"];
    

    return newString;
}

-(void)sendNotice{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send Email", @"Print Notes", nil];
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [self sendEmail];
    } else if (buttonIndex == 1){
        [self printNotes];
    }
}

- (void)printNotes{
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.jobName = self.activeTask.title;
    pic.printInfo = printInfo;
    
    UIMarkupTextPrintFormatter *notesFormatter = [[UIMarkupTextPrintFormatter alloc]
                                        initWithMarkupText:[self printString]];
    notesFormatter.startPage = 0;
    CCPrintNotesRender *renderer = [[CCPrintNotesRender alloc] init];
    renderer.headerString = [NSString stringWithFormat:@"Task Notes for %@ task", self.activeTask.title];
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

/*void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
    if (!completed && error)
        NSLog(@"FAILED! due to error in domain %@ with error code %u",
              error.domain, error.code);
};*/

- (void)sendEmail{
    [self resignFirstResponder];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mailComposer = [[MFMailComposeViewController alloc] init];
    self.mailComposer.mailComposeDelegate = self;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    NSArray *recipients = nil;
    if (self.activeTask.assignedTo != nil) {
        recipients = [[NSArray alloc] initWithObjects:[self getMailingAddress], nil];
    } else if ( [defaults stringArrayForKey:kDefaultEmail] != nil ){
        recipients = [[NSArray alloc] initWithObjects:[defaults stringArrayForKey:kDefaultEmail], nil];
    }
    
    NSString *newString = [self printString];
    
    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
    self.mailComposer.mailComposeDelegate = self;
    [self.mailComposer setSubject:[[NSString alloc] initWithFormat:@"Task Assignment for Project: %@", self.activeTask.taskProject.projectName]];
    [self.mailComposer setToRecipients:recipients ];
    [self.mailComposer setMessageBody:newString isHTML:YES];
    self.mailComposer.mailComposeDelegate = self;
    [self presentViewController:self.mailComposer animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result == MFMailComposeResultCancelled) {
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    self.mailComposer = nil;
    // self.view.frame = self.rect;
    //[self.navigationController popViewControllerAnimated:YES];
}

-(Priority *)getCurrentCategory{
    return self.activeTask.taskPriority;
}

-(void)saveSelectedCategory:(Priority *)newCategory{
    self.activeTask.taskPriority = newCategory;
}

#pragma mark - Addressbook delegates
- (BOOL)checkIsDeviceVersionHigherThanRequiredVersion:(NSString *)requiredVersion
{
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:requiredVersion options:NSNumericSearch] != NSOrderedAscending)
    {
        return YES;
    }
    
    return NO;
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    self.activeTask.assignedTo = nil;
    self.activeTask.assignedFirst = nil;
    self.activeTask.assignedLast = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    [self displayPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

-(void)displayPerson:(ABRecordRef)person{
    NSString *name =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName =  (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.activeTask.assignedFirst = name;
    self.activeTask.assignedLast = lastName;
    self.activeTask.assignedTo = [[NSString alloc] initWithFormat:@"%@ %@", name, lastName];
    [self.taskParameters reloadData];
}

#pragma mark - View Lifecycle

-(void)viewWillAppear:(BOOL)animated{
    if (self.activeTask.superTask != nil) {
        [self.activeTask.superTask setNewDisplayOrderWith:self.activeTask.superTask.displayOrder];
    }
    self.taskTitle.text = self.activeTask.title;
    self.notes = self.activeTask.notes;
    self.activeTask.taskUUID = self.activeTask.taskUUID ? self.activeTask.taskUUID : [[CoreData sharedModel:nil] getUUID];
    BOOL activeVal = [self.activeTask.completed boolValue];
    [self.status setOn:activeVal];
    UIBarButtonItem *newButton = nil;
    if ([self.taskDelegate shouldShowCancelButton]) {
        newButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAddTask)];
    } else {
        newButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendNotice)];
    }
    self.navigationItem.rightBarButtonItem = newButton;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [self.taskParameters reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.activeTask.notes = self.notes;
    [self.taskDelegate savePopoverData];
    [self.view endEditing:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Task Details";
    self.taskParameters.delegate = self;
    self.taskParameters.dataSource = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)callOwnerController{
    if ([self checkIsDeviceVersionHigherThanRequiredVersion:@"6.0"]) {
        self.ownerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        self.rect = self.view.frame;
        self.ownerController.preferredContentSize = self.rect.size;
    } else {
        self.ownerController.modalPresentationStyle = UIModalPresentationFormSheet;
        self.ownerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    self.ownerController.peoplePickerDelegate = self;
    [self presentViewController:self.ownerController animated:YES completion:nil];
}

-(void)callDueDateController{
    self.dueDateController.activeTask = self.activeTask;
    [self.navigationController pushViewController:self.dueDateController animated:YES];
}

-(void)callParentTaskController{
    self.parentController.popDelegate = self;
    self.parentController.activeTask = self.activeTask;
    self.parentController.parentTask = self.activeTask.superTask;
    [self.navigationController pushViewController:self.parentController animated:YES];
}

-(void)callIntervalController{
    self.durationController.durationDelegate = self;
    self.durationController.spinnerValue = self.activeTask.duration;
    [self.navigationController pushViewController:self.durationController animated:YES];
}

-(void)callCategoryController{
    self.categoryController.categoryDelegate = self;
    [self.navigationController pushViewController:self.categoryController animated:YES];
}

#pragma mark - Table controls
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedIndexPath = indexPath;
    self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    switch ([indexPath row]) {
        case 0:
            [self callDueDateController];
            break;
        case 1:
            [self callOwnerController];
            break;
        case 2:
            [self callIntervalController];
            break;
        case 3:
            [self callCategoryController];
            break;
        case 4:
            [self callParentTaskController];
            break;
        default:
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger result = 4;
    
    if (![self.activeTask.completed boolValue]) {
        result = 5;
    }
    
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *taskOwner;
    if (self.activeTask.assignedTo == nil) {
        taskOwner = @"Self";
    } else {
        taskOwner = self.activeTask.assignedTo;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    UITableViewCell *cell = nil;
    static NSString *dueDateID = @"dueDateCell";
    static NSString *assignedID = @"assignedCell";
    static NSString *childOfID = @"childOfCell";
    static NSString *durationCellID = @"durationCell";
    static NSString *priorityCellID = @"priorityCell";
    
     NSUInteger row = [indexPath row];
    if (row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:dueDateID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:dueDateID];
        }
        cell.detailTextLabel.text = [formatter stringFromDate:self.activeTask.dueDate];
    } else if (row == 1 ){
        cell = [tableView dequeueReusableCellWithIdentifier:assignedID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:assignedID];
        }
        cell.detailTextLabel.text = taskOwner;
    } else if (row == 2 ){
        cell = [tableView dequeueReusableCellWithIdentifier:durationCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:durationCellID];
        }
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%d Hours", [self.activeTask.duration integerValue]];
    } else if (row == 3 ){
        cell = [tableView dequeueReusableCellWithIdentifier:priorityCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:priorityCellID];
        }
        if (self.activeTask.taskPriority == nil) {
            cell.detailTextLabel.text = @"Not set";
        } else {
            cell.detailTextLabel.text = self.activeTask.taskPriority.priority;
        }
    } else if (row == 4){
        cell = [tableView dequeueReusableCellWithIdentifier:childOfID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1
                    reuseIdentifier:childOfID];
        }
        if (self.activeTask.superTask != nil) {
            cell.detailTextLabel.text = self.activeTask.superTask.title;
        } else {
            cell.detailTextLabel.text = @"Itself";
        }
    }
    return cell;
}

#pragma mark - Lazy getters
-(CCTaskDueDateViewController *)dueDateController{
    if (_dueDateController == nil) {
        _dueDateController = [self.storyboard instantiateViewControllerWithIdentifier:@"taskDueDate"];
    }
    return _dueDateController;
}

-(CCParentTaskViewController *)parentController{
    if (_parentController == nil) {
        _parentController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"taskOwner"];
    }
    return _parentController;
}

-(ABPeoplePickerNavigationController *)ownerController{
    if (_ownerController == nil) {
        _ownerController = [[ABPeoplePickerNavigationController alloc] init];
    }
    return _ownerController;
}

-(CCAuxDurationViewController *)durationController{
    if (_durationController == nil) {
        _durationController = [self.storyboard instantiateViewControllerWithIdentifier:@"durationViewController"];
    }
    return _durationController;
}

-(CCExpenseNotesViewController *)notesController{
    if (_notesController == nil) {
        _notesController = [self.storyboard instantiateViewControllerWithIdentifier:@"expenseNotes"];
    }
    return _notesController;
}

-(CCCategoryTaskViewController *)categoryController{
    if (_categoryController == nil) {
        _categoryController = [self.storyboard instantiateViewControllerWithIdentifier:@"categoryViewController"];
    }
    return _categoryController;
}

@end
