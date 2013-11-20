//
//  CCProjectSwitchTableViewController.m
//  SyncMyProject
//
//  Created by Ken Cluff on 9/5/12.
//
//

#import "CCProjectSwitchTableViewController.h"

@interface CCProjectSwitchTableViewController ()

@end

@implementation CCProjectSwitchTableViewController
@synthesize fetchRequest = _fetchRequest;
@synthesize projectFRC = _projectFRC;
@synthesize selectedProject = _selectedProject;
@synthesize currentTimer = _currentTimer;

#pragma mark - View Lifecycle

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
    NSSortDescriptor *completeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"complete" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: projectNameDescriptor, completeDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    self.projectFRC.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    self.projectFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    
    NSError *requestError = nil;
    if ([self.projectFRC performFetch:&requestError]) {
        [self.tableView reloadData];
    }
    NSUInteger rowPointer = -1;
    
    if (self.currentTask != nil) {
        // Displaying tasks
        self.navigationItem.title = @"Task List";
        int i = 0;
        for (Task *task in self.currentTimer.workProject.projectTask.allObjects) {
            if ([task.taskUUID isEqualToString:self.currentTask.taskUUID]) {
                rowPointer = i;
                break;
            }
            i++;
        }
    } else {
        // Displaying projects
        for (Project *project in [self.projectFRC fetchedObjects]) {
            if ([self.selectedProject.projectUUID isEqualToString:project.projectUUID]) {
                rowPointer = [[self.projectFRC fetchedObjects] indexOfObject:project];
                break;
            }
        }
    }
    NSIndexPath *projectIndex = [NSIndexPath indexPathForRow:rowPointer inSection:0];
    [self.tableView selectRowAtIndexPath:projectIndex animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger retValue;
    if (self.currentTask == nil) {
        retValue = [[self.projectFRC sections] count];
    } else {
        retValue = 1;
    }
    // Return the number of sections.
    return retValue;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger retValue;
    // Return the number of rows in the section.
    if (self.currentTask == nil) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.projectFRC sections] objectAtIndex:section];
        retValue = [sectionInfo numberOfObjects];
    } else {
        retValue = self.currentTimer.workProject.projectTask.count;
    }
    return retValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"projectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (self.currentTask == nil) {
        cell.textLabel.text = [[self.projectFRC objectAtIndexPath:indexPath] projectName];
    } else {
        Task *task = (Task *)self.currentTimer.workProject.projectTask.allObjects[indexPath.row];
        cell.textLabel.text = task.title;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath != nil) {
        if (self.currentTask == nil) {
            Project *newProject = [self.projectFRC objectAtIndexPath:indexPath];
            if (![self.selectedProject.projectName isEqualToString:newProject.projectName]){
                WorkTime *transferedEvent = [NSEntityDescription insertNewObjectForEntityForName:@"WorkTime" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
                
                if (transferedEvent != nil && [[CoreData sharedModel:nil] managedObjectContext] != nil) {
                    transferedEvent.billed = self.currentTimer.billed;
                    transferedEvent.start = self.currentTimer.start;
                    transferedEvent.end = self.currentTimer.end;
                    transferedEvent.workProject = newProject;
                    
                    [self.selectedProject removeProjectWorkObject:self.currentTimer];
                    
                    if (newProject != nil && transferedEvent != nil) {
                        [newProject addProjectWorkObject:transferedEvent];
                    }
                }
            }
            // Since we're changing projects, we no longer need this. Go all the way to summary
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            // Since we're in the same project, go back to see how things look with the change.
            self.currentTask = self.currentTimer.workProject.projectTask.allObjects[indexPath.row];
            self.currentTimer.workTask = self.currentTask;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}


@end
