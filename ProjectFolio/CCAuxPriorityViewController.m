//
//  CCAuxPriorityViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/17/12.
//
//

#import "CCAuxPriorityViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CCAuxPriorityViewController ()

@property (strong, nonatomic) NSFetchedResultsController *priorityFRC;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) CCAuxPriorityEditorViewController *editor;
@property (strong, nonatomic) NSIndexPath *selectedPath;
@property (strong, nonatomic) Priority *theNewPriority;
@property (strong, nonatomic) CCErrorLogger *logger;
@property (strong, nonatomic) NSArray *priorityList;
@end

@implementation CCAuxPriorityViewController

-(IBAction)insertPriority:(UIBarButtonItem *)sender{
    Priority * newPriority = [NSEntityDescription
                              insertNewObjectForEntityForName:@"Priority"
                              inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    self.selectedPath = nil;
    self.theNewPriority = newPriority;
    self.editor.contentSizeForViewInPopover = self.view.bounds.size;
    [self.navigationController pushViewController:self.editor animated:YES];
}

#pragma mark - <CCPriorityDetailDelegate>
-(void)saveUpdatedDetail:(NSString *)newValue{
    if (self.selectedPath == nil) {
        self.theNewPriority.priority = newValue;
        [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
    } else {
        Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
        priority.priority = newValue;
    }
}

-(NSString *)getDetailValue{
    Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
    return priority.priority;
}

- (NSString *)getPriorityColor
{
Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
   return priority.color;
}

- (void)saveUpdatedColor:(NSString *)newValue
{
    Priority *priority = [self.priorityFRC objectAtIndexPath:self.selectedPath];
    priority.color = newValue;
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Priority" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *purchaseDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: purchaseDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.priorityFRC.delegate = self;
    self.priorityFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
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
    
    [[[CoreData sharedModel:nil] managedObjectContext] deleteObject:[self.priorityFRC objectAtIndexPath:indexPath]];
    
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
    UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(250, 5, 44, 34)];
    catColor.backgroundColor = [priority getCategoryColor];
    catColor.layer.cornerRadius = 3;
    catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    catColor.layer.borderWidth = 1;
    [cell addSubview:catColor];
    cell.textLabel.text = priority.priority;
    return cell;
}

#pragma mark - Lazy Getters
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
