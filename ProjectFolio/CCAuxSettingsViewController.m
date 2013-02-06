//
//  CCAuxSettingsViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import "CCAuxSettingsViewController.h"

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

@interface CCAuxSettingsViewController ()

@property (strong, nonatomic) CCLocationController *locationManager;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) CCAuxPriorityViewController *priorityController;
@property (strong, nonatomic) CCAuxCalendarSettingViewController *calendarController;
@end

@implementation CCAuxSettingsViewController
@synthesize changeFontSize = _changeFontSize;
@synthesize tableView = _tableView;
@synthesize defaults = _defaults;
@synthesize colorPad = _colorPad;
@synthesize locationManager = _locationManager;
@synthesize email = _email;
@synthesize logger = _logger;
@synthesize priorityController = _priorityController;
@synthesize calendarController = _calendarController;

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
        self.location.text = [[NSString alloc] initWithFormat:@"Click button to set home location"];
    } else {
        if (address.subThoroughfare == nil && address.thoroughfare == nil && address.locality == nil) {
            self.location.text = [[NSString alloc] initWithFormat:@"Click button to set home location"];
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
    
    self.colorPad.layer.borderWidth = 1.25f;
    self.colorPad.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    for (UIView *view in self.colorPad.subviews) {
        view.layer.borderWidth = 1.25f;
        view.layer.borderColor = [[UIColor darkGrayColor]CGColor];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.email.text = [self.defaults objectForKey:kDefaultEmail];
    NSString * homeLocation = [self.defaults objectForKey:kHomeLocation];
    NSString *latitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:0];
    NSString *longitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:1];
    [self getAddressFromLat:latitude andLong:longitude];

}

- (void)viewDidUnload
{
    self.changeFontSize = nil;
    self.tableView = nil;
    self.defaults = nil;
    self.location = nil;
    self.email = nil;
    self.logger = nil;
    self.priorityController = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - IBActions
-(IBAction)email:(UITextField *)sender{
    [self.defaults setObject:sender.text forKey:kDefaultEmail];
}

-(IBAction)openFAQ:(UIButton *)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.weatherbytes.net/pf/faq/faq.html"]];
}

-(IBAction)setHomeLocation:(UIButton *)sender{
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

-(IBAction)tapHandler:(UITapGestureRecognizer *)sender{
    CGPoint currentTouch = [sender locationInView:self.colorPad];
    int x = currentTouch.x;
    int y = currentTouch.y;
    int z = 0;
    if (x > 10 &&  x < 71){
        x = 1;
    } else if ( x > 78 && x < 139 ){
        x = 2;
    } else if ( x > 146 && x < 207) {
        x = 3;
    } else if ( x > 214 && x < 275) {
        x = 4;
    }
    
    z = x - 1;
    if (y >= 10 &&  y < 71){
        y = 1;
    } else if ( y > 78 && y < 139 ){
        y = 2;
    } else if ( y > 146 && y < 207) {
        y = 3;
    }
    y = y - 1;
    z = z + ( y * 4 );
    if (z < 0 || z > 11) {
        z = 0;
    }
    
    // NSLog(@"x: %d y: %d view pointer: %d", x, y, z);
    
    UIView *subView = [self.colorPad.subviews objectAtIndex:z];
    UIColor *viewColor = subView.backgroundColor;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    BOOL answer = [viewColor getRed:&red green:&green blue:&blue alpha:&alpha];
    if (answer == YES) {
        [self.defaults setFloat:red forKey:kRedNameKey];
        [self.defaults setFloat:green forKey:kGreenNameKey];
        [self.defaults setFloat:blue forKey:kBlueNameKey];
        [self.defaults setFloat:alpha forKey:kSaturation];
        NSString *colorChangeNotification = [[NSString alloc] initWithFormat:@"%@", @"BackGroundColorChangeNotification"];
        NSNotification *colorChange = [NSNotification notificationWithName:colorChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:colorChange];
    }
}

- (IBAction)changeFontSize:(UIStepper *)sender {
    [self.defaults setInteger:sender.value forKey:kFontSize];
    NSString *fontChangeNotification = [[NSString alloc] initWithFormat:@"%@", @"FontChangeNotification"];
    NSNotification *fontChange = [NSNotification notificationWithName:fontChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:fontChange];
}



#pragma mark - Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger returnValue = 0;
    if (section == 0) {
        returnValue = 3;
    }
    return returnValue;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *fontSettingCell = @"fontSetting";
    static NSString *calendarCellID = @"calendarCell";
    static NSString *priorityCellID = @"priorityCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:fontSettingCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:fontSettingCell];
        }
        cell.detailTextLabel.text = [self.defaults  objectForKey:kFontNameKey];
    } else if (indexPath.row == 2 && indexPath.section == 0){
        cell = [tableView dequeueReusableCellWithIdentifier:priorityCellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:priorityCellID];
        }
    } else if (indexPath.row == 1 && indexPath.section == 0){
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
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (indexPath.row == 0 && indexPath.section == 0) {
        [self performSegueWithIdentifier:@"showFonts" sender:self];
    } else  if ( indexPath.row == 1 && indexPath.section == 0 ) {
        self.calendarController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
        [self.navigationController pushViewController:self.calendarController animated:YES];
    } else {
        self.priorityController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
        [self.navigationController pushViewController:self.priorityController animated:YES];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"showFonts"]) {
        UIViewController *destinationView = [segue destinationViewController];
        destinationView.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    }
}

#pragma mark - Lazy Getter
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

@end
