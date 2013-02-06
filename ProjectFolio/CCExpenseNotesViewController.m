//
//  CCExpenseNotesViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/20/12.
//
//

#import "CCExpenseNotesViewController.h"
#define kFontNameKey @"font"
#define kFontSize @"fontSize"
#define kBlueNameKey @"bluebalance"
#define kRedNameKey @"redbalance"
#define kGreenNameKey @"greenbalance"
#define kSaturation @"saturation"

@interface CCExpenseNotesViewController ()
@property (strong, nonatomic) UIMenuItem *longPressMenu;

@end

@implementation CCExpenseNotesViewController
@synthesize notes = _notes;
@synthesize expense = _expense;
@synthesize notesDelegate = _notesDelegate;
@synthesize longPressMenu = _longPressMenu;

-(void)setFontForDisplay{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontFamily = [[NSString alloc] initWithFormat:@"%@", [defaults objectForKey:kFontNameKey]];
    CGFloat fontSize = [defaults integerForKey:kFontSize];
    UIFont *displayFont = [UIFont fontWithName:fontFamily size:fontSize];
    self.notes.font = displayFont;
}

-(void)setDisplayBackGroundColor{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat alpha = [defaults floatForKey:kSaturation];
    CGFloat red = [defaults floatForKey:kRedNameKey];
    CGFloat blue = [defaults floatForKey:kBlueNameKey];
    CGFloat green = [defaults floatForKey:kGreenNameKey];
    UIColor *newColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    self.notes.backgroundColor = newColor;
}

-(IBAction)closeNotes:(UIBarButtonItem *)sender{
    [self.notesDelegate releaseNotes];
}

#pragma mark - Handle custom menu
-(void)handleCustomMenu{
    NSRange range = self.notes.selectedRange;
    if (range.length > 0) {
        NSString *selectedString = [self.notes.text substringWithRange:range];
        NSArray *componentsSeparatedByNewLines = [selectedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        Task *parentTask = [self.notesDelegate getParentTask];
        Project *owningProject = parentTask.taskProject;
        int nextLevel = [parentTask.level integerValue];
        nextLevel++;
        float newDisplayOrder = [parentTask.displayOrder floatValue] + 0.1f;
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
                newTask.taskProject = owningProject;
                newDisplayOrder = newDisplayOrder + 0.001f;
                newTask.displayOrder = [NSNumber numberWithFloat:newDisplayOrder];
                newTask.level = [NSNumber numberWithInt:nextLevel];
                newTask.superTask = parentTask;
                [owningProject addProjectTaskObject:newTask];
                self.notes.selectedTextRange = nil;
                NSString *addTaskNotification = [[NSString alloc] initWithFormat:@"%@", @"newTaskNotification"];
                NSNotification *newTaskNotification = [NSNotification notificationWithName:addTaskNotification object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:newTaskNotification];
            }
        }
    }
    [self.notes resignFirstResponder];
}


#pragma mark - Handle Keyboard
-(void) handleKeyboardDidShow:(NSNotification *)paramNotification{
    NSValue *keyboardRectAsObject = [[paramNotification userInfo]
                                     objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect;
    
    [keyboardRectAsObject getValue:&keyboardRect];
    
    BOOL isPortrait = UIDeviceOrientationIsPortrait(self.interfaceOrientation);
    UIEdgeInsets contentInsets;
    // NSLog(@"Keyboard height: %f width: %f", keyboardRect.size.height, keyboardRect.size.width);
    if (isPortrait) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardRect.size.height, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardRect.size.width, 0.0);
    }
    
    self.notes.contentInset = contentInsets;
}

-(void) handleKeyboardWillHide:(NSNotification *)paramNotification{
    self.notes.contentInset = UIEdgeInsetsZero;
}


#pragma mark - Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self setDisplayBackGroundColor];
    [self setFontForDisplay];
    self.notes.text = [self.notesDelegate getNotes];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleKeyboardDidShow:)
     name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleKeyboardWillHide:)
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if ([self.notesDelegate isTaskClass] == YES) {
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
    }
}

-(void)viewDidUnload{
    self.notes = nil;
    self.expense = nil;
    self.longPressMenu = nil;
    self.notesDelegate = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
