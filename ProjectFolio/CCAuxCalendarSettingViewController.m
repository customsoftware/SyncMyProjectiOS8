//
//  CCAuxCalendarSettingViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/22/12.
//
//

#import "CCAuxCalendarSettingViewController.h"
#define kDefaultCalendar @"defaultCalendar"

@interface CCAuxCalendarSettingViewController ()

@property (strong, nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) NSArray *calendarList;
@property (strong, nonatomic) NSArray *calendarTypes;
@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation CCAuxCalendarSettingViewController

#pragma mark - Life Cycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];    
    self.eventStore = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.calendarTypes = @[@"Local", @"iCloud/CalDAV", @"Exchange", @"Subscription", @"Birthday"];
    NSMutableArray *workingList = [[NSMutableArray alloc] init];
    for (EKCalendar *thisCalendar in self.eventStore.calendars) {
        [workingList addObject:thisCalendar];
    }
    self.calendarList = [NSArray arrayWithArray:workingList];
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated{
    NSString *currentCalendar = [self.defaults objectForKey:kDefaultCalendar];
    if (currentCalendar != nil) {
        NSUInteger index = -1;
        for (EKCalendar *calendar in self.calendarList) {
            NSString *comparisonString = [[NSString alloc] initWithFormat:@"%@ in (%@)", calendar.title, [self.calendarTypes objectAtIndex:calendar.type]];
            if ([comparisonString isEqualToString:currentCalendar]) {
                index = [self.calendarList indexOfObject:calendar];
                break;
            }
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } else {
        [self.tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)cancelCalendar:(UIBarButtonItem *)sender{
    [self.defaults setValue:nil forKey:kDefaultCalendar];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.calendarList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"calendarCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    EKCalendar *calendar = [self.calendarList objectAtIndex:indexPath.row];
    cell.textLabel.text = [[NSString alloc] initWithFormat:@"%@ in (%@)", calendar.title, [self.calendarTypes objectAtIndex:calendar.type]];
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *calendarName = cell.textLabel.text;
    [self.defaults setValue:calendarName forKey:kDefaultCalendar];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Lazy Getters
-(EKEventStore *)eventStore{
    if (_eventStore == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _eventStore = application.eventStore;
    }
    return _eventStore;
}

-(NSUserDefaults *)defaults{
    if (_defaults == nil) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

@end
