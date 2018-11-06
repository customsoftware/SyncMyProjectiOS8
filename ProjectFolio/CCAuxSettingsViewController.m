//
//  CCAuxSettingsViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import "CCAuxSettingsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CCColorViewController.h"
#import "CCSettingsControl.h"
#import "CCAuxPriorityViewController.h"
#import "CCAuxCalendarSettingViewController.h"
#import "CCMasterViewController.h"
#import "CCAuxFontListViewController.h"
#import "CCAppDelegate.h"
#import "CCUpgradesViewController.h"

#define kFontNameKey @"font"
#define kFontSize @"fontSize"
#define kShowProjects @"neverShowProjects"
#define kFontNameKey @"font"
#define kBlueNameKey @"bluebalance"
#define kRedNameKey @"redbalance"
#define kGreenNameKey @"greenbalance"
#define kSaturation @"saturation"
#define kDefaultEmail @"defaultEmail"
#define kHomeLocation @"homeLocation"
#define kDefaultCalendar @"defaultCalendar"

@interface CCAuxSettingsViewController () <UIScrollViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) CCLocationController *locationManager;
@property (strong, nonatomic) CCSettingsControl *settings;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) CCAuxPriorityViewController *priorityController;
@property (strong, nonatomic) CCAuxCalendarSettingViewController *calendarController;
@property (strong, nonatomic) CCColorViewController *colorController;
@property (strong, nonatomic) CCUpgradesViewController *upgrades;

@property (weak, nonatomic) IBOutlet UISwitch *activeEnabledSwitch;
@property (weak, nonatomic) IBOutlet UIScrollView *scroller;
@property (weak, nonatomic) IBOutlet UIStepper *changeFontSize;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UISwitch *timerOffOn;
@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (weak, nonatomic) IBOutlet UISwitch *expenseSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *timeSwitch;

- (IBAction)declareDeviceAsDesignatedTimer:(UISwitch *)sender;
- (IBAction)enableTimingOfInactiveProjects:(UISwitch *)sender;
@end

@implementation CCAuxSettingsViewController

#pragma mark - Life Cycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setReverseGeoCodeError{
    self.location.text = @"Failed to find address";
}

-(void)setReverseGeoCodeSuccessWithPlacemark:(NSArray *)placemark{
    CLPlacemark *address = [placemark objectAtIndex:0];
    if (address == nil) {
        self.location.text = [[NSString alloc] initWithFormat:@"Tap button to set home location"];
    } else {
        if (address.subThoroughfare == nil && address.thoroughfare == nil && address.locality == nil) {
            self.location.text = [[NSString alloc] initWithFormat:@"Tap button to set home location"];
        } else {
            self.location.text = [[NSString alloc] initWithFormat:@"%@ %@, %@", address.subThoroughfare, address.thoroughfare, address.locality];
        }
    }
}

-(void)getAddressFromLat:(NSString *)latitude andLong:(NSString *)longitude{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            [self setReverseGeoCodeError];
        } else {
            [self setReverseGeoCodeSuccessWithPlacemark:placemarks];
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTimer) name:kAppString object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.email.text = [self.defaults objectForKey:kDefaultEmail];
    NSString * homeLocation = [self.defaults objectForKey:kHomeLocation];
    [self.activeEnabledSwitch setOn:[self.defaults boolForKey:kInActiveEnabled]];
    NSString *latitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:0];
    NSString *longitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:1];
    [self getAddressFromLat:latitude andLong:longitude];
    [self updateTimer];
/*Alternative is to have timer run locally on each device, but better is to have one device time and the others watch*/
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scroller setScrollEnabled:YES];
    self.scroller.contentSize = CGSizeMake(320, 600);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateTimer{
    BOOL keyStatus = [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus];
    NSString *localDeviceGUID = [[NSUserDefaults standardUserDefaults] objectForKey:kAppString];
    
    // Get Cloud status
    NSString *controllingAppID = nil;
    NSDictionary *cloudDictionary = [[CoreData sharedModel:nil] cloudDictionary];
    if (cloudDictionary != nil ) {
        if (cloudDictionary[kAppString]) {
            controllingAppID = cloudDictionary[kAppString];
            if ([localDeviceGUID isEqualToString:controllingAppID]){
                keyStatus = YES;
            } else {
                keyStatus = NO;
            }
        } else {
            keyStatus = YES;
        }
        
        if (cloudDictionary[kDefaultEmail]) {
            self.email.text = cloudDictionary[kDefaultEmail];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:keyStatus forKey:kAppStatus];
    [self.timerOffOn setOn:keyStatus];
    self.timerOffOn.enabled = YES;
    
    [self.timeSwitch setOn:keyStatus];
    [self.activeEnabledSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kInActiveEnabled]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.email resignFirstResponder];
}

#pragma mark - IBActions
-(IBAction)declareDeviceAsDesignatedTimer:(UISwitch *)sender{
    BOOL keyStatus = [sender isOn];
    [self.email resignFirstResponder];
    if (keyStatus == YES) {
        NSString *deviceGUID = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kAppString];
        [[[CoreData sharedModel:nil] iCloudKey] setString:deviceGUID forKey:kAppString];
    }
    [[NSUserDefaults standardUserDefaults] setBool:keyStatus forKey:kAppStatus];

    [self updateTimer];
}

- (IBAction)enableTimingOfInactiveProjects:(UISwitch *)sender {
    [self.defaults setBool:sender.isOn forKey:kInActiveEnabled];
}

-(IBAction)email:(UITextField *)sender {
    [self.defaults setObject:sender.text forKey:kDefaultEmail];
    [[[CoreData sharedModel:nil] iCloudKey] setString:sender.text forKey:kDefaultEmail];
}

-(IBAction)openFAQ:(UIButton *)sender{
    [self.email resignFirstResponder];
    [self performSegueWithIdentifier:@"pushPurchases" sender:self];
}

-(IBAction)setHomeLocation:(UIButton *)sender{
    [self.email resignFirstResponder];
    [self.locationManager getLocation];
}

-(void)locationUpdate:(CLLocation *)location{
    NSString *newLocation = [[NSString alloc] initWithFormat:@"%+.6f\\%+.6f", location.coordinate.latitude, location.coordinate.longitude];
    NSString *latitude = [[newLocation componentsSeparatedByString:@"\\"] objectAtIndex:0];
    NSString *longitude = [[newLocation componentsSeparatedByString:@"\\"] objectAtIndex:1];
    [self getAddressFromLat:latitude andLong:longitude];
    [self.defaults setValue:newLocation forKey:kHomeLocation];
    self.locationManager = nil;
}

-(void)locationError:(NSError *)error{
    self.location.text = @"Location search failed";
    self.locationManager = nil;
}

-(void)releaseLogger{
    self.logger = nil;
}

- (IBAction)changeFontSize:(UIStepper *)sender {
    [self.defaults setInteger:sender.value forKey:kFontSize];
    NSString *fontChangeNotification = [[NSString alloc] initWithFormat:@"%@", @"FontChangeNotification"];
    NSNotification *fontChange = [NSNotification notificationWithName:fontChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:fontChange];
}

#pragma mark - Delegats
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // Go to the purchase feature here
        self.upgrades.preferredContentSize = self.view.bounds.size;
        [self.navigationController pushViewController:self.upgrades animated:YES];
    } else {
        if (alertView.tag == timingAlert) {
            [self.timeSwitch setOn:NO];
        } else if ( alertView.tag == expenseAlert ) {
            [self.expenseSwitch setOn:NO];
        }
    }
}

#pragma mark - Table view data source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger returnValue = 5;
    return returnValue;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *fontSettingCell = @"fontSetting";
    static NSString *calendarCellID = @"calendarCell";
    static NSString *priorityCellID = @"priorityCell";
    static NSString *tintCellID = @"tintCell";
    static NSString *colorCellID = @"colorCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.row == settingFontOption) {
        cell = [tableView dequeueReusableCellWithIdentifier:fontSettingCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:fontSettingCell];
        }
        cell.detailTextLabel.text = [self.defaults  objectForKey:kFontNameKey];
    } else if (indexPath.row == settingCalendarOption){
        cell = [tableView dequeueReusableCellWithIdentifier:calendarCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:calendarCellID];
        }
        cell.detailTextLabel.text = [self.defaults objectForKey:kDefaultCalendar];
        if ([cell.detailTextLabel.text length] > 0) {
            cell.textLabel.text = nil;
        } else {
            cell.textLabel.text = @"Set Default Calendar";
        }
    } else if (indexPath.row == settingCatgoryOption){
        cell = [tableView dequeueReusableCellWithIdentifier:priorityCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:priorityCellID];
        }
    } else if (indexPath.row == settingTintOption){
        cell = [tableView dequeueReusableCellWithIdentifier:tintCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tintCellID];
        }
    } else /*if (indexPath.row == settingBGColorOption)*/ {
        cell = [tableView dequeueReusableCellWithIdentifier:colorCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:colorCellID];
        }
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.email resignFirstResponder];
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.row == settingFontOption) {
        [self performSegueWithIdentifier:@"showFonts" sender:self];
    } else if ( indexPath.row == settingCalendarOption ) {
        [self.navigationController pushViewController:self.calendarController animated:YES];
    } else if ( indexPath.row == settingCatgoryOption ) {
        [self.navigationController pushViewController:self.priorityController animated:YES];
    } else if ( indexPath.row == settingTintOption ) {
        self.colorController.colorMode = @"Tint";
        [self.navigationController pushViewController:self.colorController animated:YES];
    } else if ( indexPath.row == settingBGColorOption ) {
        self.colorController.colorMode = @"BackGround";
        [self.navigationController pushViewController:self.colorController animated:YES];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"showFonts"]) {
        UIViewController *destinationView = [segue destinationViewController];
        destinationView.preferredContentSize = self.preferredContentSize;
    } else if ( [segue.identifier isEqualToString:@"pushPurchases"]) {
        UIViewController *destinationView = [segue destinationViewController];
        destinationView.preferredContentSize = self.view.frame.size;
    }
}

#pragma mark - Lazy Getter
-(CCSettingsControl *)settings{
    if (_settings == nil) {
        _settings = [[CCSettingsControl alloc] init];
    }
    return _settings;
}

-(NSUserDefaults *)defaults{
    if (_defaults == nil) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return _defaults;
}

-(CCLocationController *)locationManager{
    if (_locationManager == nil) {
        _locationManager = [[CCLocationController alloc] init];
        _locationManager.locationDelegate = self;
    }
    return _locationManager;
}

-(CCAuxPriorityViewController *)priorityController{
    if (_priorityController == nil) {
        _priorityController = [self.storyboard instantiateViewControllerWithIdentifier:@"priorityEditor"];
    }
    return _priorityController;
}

-(CCAuxCalendarSettingViewController *)calendarController{
    if (_calendarController == nil) {
        _calendarController = [self.storyboard instantiateViewControllerWithIdentifier:@"calendarSettings"];
    }
    return _calendarController;
}

-(CCColorViewController *)colorController{
    if (_colorController == nil) {
        _colorController = [self.storyboard instantiateViewControllerWithIdentifier:@"colorSettings"];
    }
    return _colorController;
}

-(CCUpgradesViewController *)upgrades{
    if (_upgrades == nil) {
        _upgrades = [self.storyboard instantiateViewControllerWithIdentifier:@"inAppUpgrades"];
    }
    return _upgrades;
}

@end
