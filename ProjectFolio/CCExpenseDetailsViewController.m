//
//  CCExpenseDetailsViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 9/3/12.
//
//

#import "CCExpenseDetailsViewController.h"
#import "CCAppDelegate.h"

#define kHomeLocation @"homeLocation"
#define SWITCH_ON [[NSNumber alloc] initWithInt:1]
#define SWITCH_OFF [[NSNumber alloc] initWithInt:0]

@interface CCExpenseDetailsViewController ()

@property (strong, nonatomic) CCExpenseNotesViewController *notesController;
@property (strong, nonatomic) UIImagePickerController *imageController;
@property (strong, nonatomic) CCLocationController *locationManager;
@property CGRect currentSize;

@end

@implementation CCExpenseDetailsViewController
@synthesize tableView = _tableView;
@synthesize expense = _expense;
@synthesize popControll = _popControll;
@synthesize notesController = _notesController;
@synthesize imageController = _imageController;
@synthesize locationManager = _locationManager;

@synthesize popDelegate = _popDelegate;
@synthesize controllingIndex = _controllingIndex;

@synthesize dateController = _dateController;
@synthesize numberFormatter = _numberFormatter;
@synthesize dateFormatter = _dateFormatter;

@synthesize itemPurchased = _itemPurchased;
@synthesize paidTo = _paidTo;
@synthesize amountPaid = _amountPaid;
@synthesize billed = _billed;
@synthesize receipt = _receipt;
@synthesize notes = _notes;
@synthesize milage = _milage;
@synthesize utilityControll = _utilityControll;
@synthesize isNew = _isNew;

#pragma mark - IBActions
-(IBAction)removePicture:(UIButton *)sender{
    self.expense.receipt = nil;
    self.receipt.image = nil;
}

-(IBAction)itemPurchased:(UITextField *)sender{
    self.expense.pmtDescription = sender.text;
    [self.view endEditing:YES];
}

-(IBAction)paidTo:(UITextField *)sender{
    self.expense.paidTo = sender.text;
    [self.view endEditing:YES];
}

-(IBAction)amountPaid:(UITextField *)sender{
    self.expense.amount = [self.numberFormatter numberFromString:sender.text];
    [self.view endEditing:YES];
}

-(IBAction)billed:(UISwitch *)sender{
    self.expense.expensed = ([sender isOn]) ? SWITCH_ON:SWITCH_OFF;
    if ([sender isOn] && self.expense.dateExpensed == nil) {
        self.expense.dateExpensed = [NSDate date];
    } else{
        self.expense.dateExpensed = nil;
    }
    [self.tableView reloadData];
}

-(IBAction)utilities:(UISegmentedControl *)sender{
    [self releaseFirstResponders];
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self performSegueWithIdentifier:@"expenseNotes" sender:self];
            break;
            
        case 1:
            [self.locationManager getLocation];
            break;
            
        case 2:
            self.imageController.delegate = self;
            [self.imageController setModalPresentationStyle:UIModalPresentationFullScreen];
            self.currentSize = self.view.frame;
            [self presentViewController:self.imageController animated:YES completion:nil];
            break;
            
        default:
            break;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"expenseNotes"]) {
        UINavigationController *viewController = (UINavigationController *)segue.destinationViewController;
        self.notesController = (CCExpenseNotesViewController *)viewController.visibleViewController;
        self.notesController.notesDelegate = self;
    }
}

-(NSString *)getNotes{
    return self.expense.notes;
}

-(BOOL)isTaskClass{
    return NO;
}

-(void)releaseNotes{
    self.expense.notes = self.notesController.notes.text;
    self.notes.text = self.expense.notes;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)setReverseGeoCodeError{
    if (self.notes.text == nil) {
        self.notes.text = @"";
    }
    self.notes.text = [[NSString alloc] initWithFormat:@"%@ %@", self.notes.text, @"Failed to find address"];
    self.expense.notes = self.notes.text;
}

-(void)setReverseGeoCodeSuccessWithPlacemark:(NSArray *)placemark{
    CLPlacemark *address = [placemark objectAtIndex:0];
    if (self.notes.text == nil) {
        self.notes.text = @"";
    }
    self.notes.text = [[NSString alloc] initWithFormat:@"%@ %@",
                       self.notes.text,
                       [[NSString alloc] initWithFormat:@"Milage to: %@ %@, %@", address.subThoroughfare, address.thoroughfare, address.locality]];
    self.expense.notes = self.notes.text;
}

-(void)getAddressFromLat:(double)latitude andLong:(double)longitude{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            [self setReverseGeoCodeError];
        } else {
            [self setReverseGeoCodeSuccessWithPlacemark:placemarks];
        }
    }];
}

-(void)locationUpdate:(CLLocation *)location{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *homeLocation = [userDefaults objectForKey:kHomeLocation];
    NSString *latitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:0];
    NSString *longitude = [[homeLocation componentsSeparatedByString:@"\\"] objectAtIndex:1];
    
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    CLLocation *toLocation = location;
    CLLocationDistance distance = [self.locationManager getApproximateMilesFrom:fromLocation To:toLocation];
    [self getAddressFromLat:location.coordinate.latitude andLong:location.coordinate.longitude];
    self.locationManager = nil;
    self.expense.milage = [NSNumber numberWithDouble:distance];
    self.milage.text = [self.numberFormatter stringFromNumber:self.expense.milage];
    self.itemPurchased.text = [[NSString alloc] initWithFormat:@"Milage: %@", self.milage.text];
    self.amountPaid.text = @"0.00";
    self.paidTo.text = @"Self";
}

-(void)locationError:(NSError *)error{
    self.milage.text = @"Location search failed";
    self.locationManager = nil;
}

-(IBAction)milage:(UITextField *)sender{
    self.expense.milage = [self.numberFormatter numberFromString:sender.text];
    if (self.expense.milage > 0) {
        self.milage.text = [self.numberFormatter stringFromNumber:self.expense.milage];
        self.itemPurchased.text = [[NSString alloc] initWithFormat:@"Milage: %@", self.milage.text];
        self.amountPaid.text = @"0.00";
        self.paidTo.text = @"Self";
    }
    [self.view endEditing:YES];
}

-(void)releaseFirstResponders{
    for (id control in self.view.subviews) {
        [control resignFirstResponder];
    }
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

-(IBAction)cancelNew{
    [self.popDelegate cancelPopover];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
        [self.utilityControll setEnabled:YES forSegmentAtIndex:2];
    } else {
        [self.utilityControll setEnabled:NO forSegmentAtIndex:2];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.receipt.layer.borderWidth = 1.50f;
    self.receipt.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadExpenseValues) name:kiCloudSyncNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.expense.paidTo = self.paidTo.text;
    self.expense.pmtDescription = self.itemPurchased.text;
    self.expense.amount = [self.numberFormatter numberFromString:self.amountPaid.text];
    [self.expense.managedObjectContext save:nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.expense.receipt = UIImagePNGRepresentation(self.receipt.image);
    }
    [self.locationManager forceShutdownOfLocator];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.tableView reloadData];
    [self releaseFirstResponders];
    [self loadExpenseValues];
    [self.view endEditing:YES];
    if ([self.popDelegate shouldShowCancelButton] ){
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelNew)];
        self.navigationItem.rightBarButtonItem = cancelButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadExpenseValues {
    self.notes.text = self.expense.notes;
    self.itemPurchased.text = self.expense.pmtDescription;
    self.amountPaid.text = [self.numberFormatter stringFromNumber:self.expense.amount];
    self.paidTo.text = self.expense.paidTo;
    self.milage.text = [self.numberFormatter stringFromNumber:self.expense.milage];
    UIImage *image = [[UIImage alloc] initWithData:self.expense.receipt];
    self.receipt.image = image;
    BOOL activeVal = [self.expense.expensed boolValue];
    [self.billed setOn:activeVal];
}

#pragma mark - Image Capture
-(BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

-(BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType) paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        // NSLog(@"Media type is empty");
    } else {
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
        [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *mediaType = (NSString *)obj;
            
            if ([mediaType isEqualToString:paramMediaType]) {
                result = YES;
                *stop = YES;
            }
        }];
    }
    
    return result;
}

-(BOOL) doesCameraSupportTakingPhotos{
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - Table Functions and Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"expenseDateCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Date purchased:";
        cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.expense.datePaid];
    } else {
        cell.textLabel.text = @"Date expensed:";
        cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.expense.dateExpensed];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.dateController =  [self.storyboard instantiateViewControllerWithIdentifier:@"projectDateSetter"];
    self.dateController.delegate = self;
    if (indexPath.row == 0) {
        self.dateController.dateValue = self.expense.datePaid;
        self.dateController.barCaption = @"Paid Date";
    } else {
        self.dateController.dateValue = self.expense.dateExpensed;
        self.dateController.barCaption = @"Expense Date";
    }
    self.dateController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    [self.navigationController pushViewController:self.dateController animated:YES];
}


#pragma mark - Delegates
-(void)saveDateValue:(NSDate *)dateValue{
    if (dateValue == nil) {
        dateValue = [NSDate date];
    }
    if ([self.dateController.barCaption isEqualToString:@"Paid Date"]) {
        self.expense.datePaid = dateValue;
    } else {
        self.expense.dateExpensed = dateValue;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]) {
        // NSDictionary *metaData = [info objectForKey:UIImagePickerControllerMediaType];
        UIImage *theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (self.receipt == nil) {
            // NSLog(@"The receipt went nil due to memory");
        } else if ( theImage == nil){
            // NSLog(@"The image went nil");
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.receipt.image = theImage;
            // NSLog(@"The receipt loaded: %f", self.receipt.image.size.height);
        } else {
            self.expense.receipt = UIImagePNGRepresentation(theImage);
        }

    }
    [self dismissViewControllerAnimated:YES completion:nil];
    self.view.frame = self.currentSize;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.view.frame = self.currentSize;
}


#pragma mark - Lazy getters
-(UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc]init];
    }
    return _tableView;
}

-(UIImagePickerController *)imageController{
    if (_imageController == nil) {
        _imageController = [[UIImagePickerController alloc ] init];
        _imageController.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSString *requiredMediaType = (__bridge NSString *)kUTTypeImage;
        _imageController.mediaTypes = [[NSArray alloc] initWithObjects:requiredMediaType, nil];
        _imageController.allowsEditing = YES;
    }
    return _imageController;
}

-(NSNumberFormatter *)numberFormatter{
    if (_numberFormatter == nil) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        [_numberFormatter setMinimumFractionDigits:2];
    }
    return _numberFormatter;
}

-(NSDateFormatter *)dateFormatter{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return _dateFormatter;
}

-(CCLocationController *)locationManager{
    if (_locationManager == nil) {
        _locationManager = [[CCLocationController alloc] init];
        _locationManager.locationDelegate = self;
    }
    return _locationManager;
}

@end
