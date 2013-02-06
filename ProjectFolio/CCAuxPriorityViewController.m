//
//  CCAuxPriorityViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import "CCAuxPriorityViewController.h"

@interface CCAuxPriorityViewController ()

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSFetchedResultsController *priorityFRC;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) CCAuxPriorityEditorViewController *editor;
@property (strong, nonatomic) NSIndexPath *selectedPath;
@property (strong, nonatomic) Priority *theNewPriority;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) NSArray *priorityList;
@end

@implementation CCAuxPriorityViewController

@synthesize tableView = _tableView;
@synthesize context = _context;
@synthesize priorityFRC = _priorityFRC;
@synthesize fetchRequest = _fetchRequest;
@synthesize editor = _editor;
@synthesize selectedPath = _selectedPath;
@synthesize theNewPriority = _theNewPriority;
@synthesize logger = _logger;
@synthesize priorityList = _priorityList;

-(IBAction)insertPriority:(UIBarButtonItem *)sender{
    Priority * newPriority = [NSEntityDescription
                              insertNewObjectForEntityForName:@"Priority"
                              inManagedObjectContext:self.context];
    self.selectedPath = nil;
    self.theNewPriority = newPriority;
    self.editor.contentSizeForViewInPopover = self.view.bounds.size;
    [self.navigationController pushViewController:self.editor animated:YES];
}

-(void)saveUpdatedDetail:(NSString *)newValue{
    if (self.selectedPath == nil) {
        self.theNewPriority.priority = newValue;
        [self.context save:nil];
    } else {
        Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
        priority.priority = newValue;
    }
}


-(NSString *)getDetailValue{
    Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
    return priority.priority;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Priority" inManagedObjectContext:self.context];
    NSSortDescriptor *purchaseDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: purchaseDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.priorityFRC.delegate = self;
    self.priorityFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:self.context
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSError *fetchError;
    [self.priorityFRC performFetch:&fetchError];
    self.priorityList = [self.priorityFRC fetchedObjects];
    [self.tableView reloadData];
}

-(void)viewDidUnload{
    self.tableView = nil;
    self.context = nil;
    self.fetchRequest = nil;
    self.priorityFRC = nil;
    self.editor = nil;
    self.selectedPath = nil;
    self.theNewPriority = nil;
    self.logger = nil;
    self.priorityList = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table Delegate & Data source
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    BOOL retValue = NO;
    Priority *priority = [self.priorityList objectAtIndex:indexPath.row];
    if ( [priority.priorityProject count] == 0 && [priority.priorityTask count] == 0) {
        retValue = YES;
    }
    return retValue;
}

-(void)deletePriorityAtIndexPath:(NSIndexPath *)indexPath{
    self.priorityFRC.delegate = nil;
    NSMutableArray *workingArray = [[NSMutableArray alloc]initWithArray:self.priorityList];
    [workingArray removeObjectAtIndex:indexPath.row];
    
    [self.context deleteObject:[self.priorityFRC objectAtIndexPath:indexPath]];
    
    NSError *fetchError = nil;
    @try {
        [self.priorityFRC performFetch:&fetchError];
    }
    @catch (NSException *exception) {
        self.logger = [[CCErrorLogger alloc] initWithError:fetchError andDelegate:self];
        [self.logger releaseLogger];
    }
    self.priorityFRC.delegate = self;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Priority *deletedPriority = [self.priorityFRC objectAtIndexPath:indexPath];
    if ([deletedPriority.priorityProject count] == 0 && [deletedPriority.priorityTask count] == 0) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the managed object for the given index path
            [self deletePriorityAtIndexPath:indexPath];
            [tableView reloadData];
        }
    }
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[self.priorityFRC fetchedObjects] count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedPath = indexPath;
    self.editor.contentSizeForViewInPopover = self.view.bounds.size;
    [self.navigationController pushViewController:self.editor animated:YES];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *priorityCellID = @"priorityCell";
    UITableViewCell * cell = nil;
    Priority *priority = [self.priorityFRC objectAtIndexPath:indexPath];
    
    cell = [tableView dequeueReusableCellWithIdentifier:priorityCellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:priorityCellID];
    }
    cell.textLabel.text = priority.priority;
    return cell;
}

#pragma mark - Lazy Getters
-(NSManagedObjectContext *)context{
    if (_context == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _context = application.managedObjectContext;
    }
    return _context;
}

-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

-(CCAuxPriorityEditorViewController *)editor{
    if (_editor == nil) {
        _editor = [self.storyboard instantiateViewControllerWithIdentifier:@"priorityValueEditor"];
        _editor.priorityDelegate = self;
    }
    return _editor;
}

@end
