//
//  CCAuxTaskCloneViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/5/12.
//
//

#import "CCAuxTaskCloneViewController.h"

@interface CCAuxTaskCloneViewController ()

@property (strong, nonatomic) NSNumberFormatter *formatter;
@property (strong, nonatomic) Project *donorProject;
@property (strong, nonatomic) CCAuxTaskCloneDrillController *driller;
@property (strong, nonatomic) NSIndexPath * selectedIndex;
@end

@implementation CCAuxTaskCloneViewController
@synthesize fetchRequest = _fetchRequest;
@synthesize projectFRC = _projectFRC;
@synthesize selectedProject = _selectedProject;
@synthesize formatter = _formatter;
@synthesize donorProject = _donorProject;
@synthesize driller = _driller;
@synthesize selectedIndex = _selectedIndex;

#pragma mark - Life Cycle
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *projectNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"projectName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: projectNameDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.projectFRC.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.projectFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                          managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                            sectionNameKeyPath:nil
                                                                     cacheName:nil];
    
    NSError *requestError = nil;
    if ([self.projectFRC performFetch:&requestError]) {
        [self.tableView reloadData];
    }
    NSUInteger rowPointer = -1;
    for (Project *project in [self.projectFRC fetchedObjects]) {
        if ([self.selectedProject.projectName isEqualToString:project.projectName]) {
            rowPointer = [[self.projectFRC fetchedObjects] indexOfObject:project];
            break;
        }
    }
    NSIndexPath *projectIndex = [NSIndexPath indexPathForRow:rowPointer inSection:0];
    [self.tableView selectRowAtIndexPath:projectIndex animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Action Sheet Functionality
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSArray *workingArray = [self.donorProject.projectTask allObjects];
        NSMutableArray *newTaskArray = [[NSMutableArray alloc] initWithCapacity:[workingArray count]];
        [self.selectedProject removeProjectTask:self.selectedProject.projectTask];
        
        for (Task *task in workingArray) {
            Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newTask.completed = [NSNumber numberWithBool:NO];
            newTask.notes = task.notes;
            newTask.title = task.title;
            newTask.active = task.active;
            newTask.displayOrder = task.displayOrder;
            newTask.visible = task.visible;
            newTask.level = task.level;
            newTask.type = task.type;
            if (task.superTask != nil) {
                newTask.superTask = task.superTask;
            }
            [newTaskArray addObject:newTask];
        }
        
        for (Task *cloneTask in newTaskArray) {
            if (cloneTask.superTask != nil) {
                // Put it in the super class
                for (Task *parent in newTaskArray) {
                    if ([parent.title isEqualToString:cloneTask.superTask.title] && [parent.displayOrder integerValue] == [cloneTask.superTask.displayOrder integerValue]) {
                        [parent addSubTasksObject:cloneTask];
                        cloneTask.superTask = parent;
                        break;
                    }
                }
            }
        }
        
        NSSet *newTasks = [[NSSet alloc] initWithArray:newTaskArray];
        [self.selectedProject addProjectTask:newTasks];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.driller.projectDelegate = self;
    self.driller.preferredContentSize = self.preferredContentSize;
    self.selectedIndex = indexPath;
    [self.navigationController pushViewController:self.driller animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.projectFRC sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.projectFRC sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static  NSString *targetCellIdentifier = @"targetCell";
    static  NSString *sourceCellIdentifier = @"sourceCell";
    UITableViewCell *cell = nil;
    
    Project *newProject = [self.projectFRC objectAtIndexPath:indexPath];
    if (![self.selectedProject.projectName isEqualToString:newProject.projectName]){
        cell = [tableView dequeueReusableCellWithIdentifier:sourceCellIdentifier];        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:targetCellIdentifier];
    }
    cell.textLabel.text = newProject.projectName;
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"No. of tasks %@", [self.formatter stringFromNumber:[NSNumber numberWithInt:(int)[newProject.projectTask count]]]];
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *currentProject = self.selectedProject;
    self.donorProject = [self.projectFRC objectAtIndexPath:indexPath];
    if (![currentProject.projectName isEqualToString:self.donorProject.projectName]){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[[NSString alloc] initWithFormat:@"Clone Tasks from %@ project. This overwrites %@'s existing tasks.", self.donorProject.projectName, currentProject.projectName] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clone Tasks" otherButtonTitles:nil];
        CGRect rect = CGRectMake(0, 0, 320, 150);
        [actionSheet showFromRect:rect inView:self.view animated:YES];
    }

}

-(Project *)getActiveProject{
    return [self.projectFRC objectAtIndexPath:self.selectedIndex];
}

-(Project *)getControllingProject{
    return self.selectedProject;
}

-(Task *)getSelectedTask{
    return nil;
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

-(NSNumberFormatter *)formatter{
    if (_formatter == nil) {
        _formatter = [[NSNumberFormatter alloc] init];
        _formatter.numberStyle = NSNumberFormatterDecimalStyle;
        [_formatter setMinimumFractionDigits:0];
    }
    return _formatter;
}

-(CCAuxTaskCloneDrillController *)driller{
    if (_driller == nil) {
        _driller = [self.storyboard instantiateViewControllerWithIdentifier:@"cloneDrill"];
    }
    return _driller;
}

@end
