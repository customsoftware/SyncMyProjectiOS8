//
//  CCAuxTaskCloneDrillController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/5/12.
//
//

#import "CCAuxTaskCloneDrillController.h"

@interface CCAuxTaskCloneDrillController ()

@property (strong, nonatomic) NSFetchRequest *request;
@property (strong, nonatomic) NSPredicate *allPredicate;
@property (strong, nonatomic) Project * donorProject;
@property (strong, nonatomic) Project * gainingProject;
@property (strong, nonatomic) NSMutableArray * taskArray;
@property (strong, nonatomic) CCAuxTaskCloneDrillController *driller;
@property (strong, nonatomic) NSIndexPath * selectedIndex;
@property (strong, nonatomic) Task *selectedTask;
@property (strong, nonatomic) Task *parentTask;

@end

@implementation CCAuxTaskCloneDrillController

@synthesize request = _request;
// @synthesize taskFRC = _taskFRC;
@synthesize allPredicate = _allPredicate;
@synthesize donorProject = _donorProject;
@synthesize gainingProject = _gainingProject;
@synthesize taskArray = _taskArray;
@synthesize driller = _driller;
@synthesize selectedIndex = _selectedIndex;
@synthesize parentTask = _parentTask;
@synthesize selectedTask = _selectedTask;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - CCProjectTaskDelegate
-(Project *)getActiveProject{
    return [self.projectDelegate getActiveProject];
}

-(Project *)getControllingProject{
    return [self.projectDelegate getControllingProject];
}

-(Task *)getSelectedTask{
    return [self.taskArray objectAtIndex:self.selectedIndex.row];
}

#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    self.donorProject = [self.projectDelegate getActiveProject];
    self.parentTask = [self.projectDelegate getSelectedTask];
    if (self.parentTask == nil) {
        self.taskArray = [NSMutableArray arrayWithArray:[self.donorProject.projectTask allObjects]];
    } else {
        self.taskArray = [NSMutableArray arrayWithArray:[self.parentTask.subTasks allObjects]];
    }
    self.title = [[NSString alloc] initWithFormat:@"Tasks: %@", self.donorProject.projectName];
    [self.tableView reloadData];
}

-(void)viewDidUnload{
    self.request = nil;
    self.allPredicate = nil;
    self.donorProject = nil;
    self.taskArray = nil;
    self.driller = nil;
    self.selectedIndex = nil;
    self.gainingProject = nil;
    self.selectedTask = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    int counter = 0;
    if (self.parentTask == nil) {
        for (Task * projectTask in self.donorProject.projectTask) {
            // NSLog(@"%@ level: %@", projectTask.title, projectTask.level);
            if ([projectTask.level integerValue] == 0) {
                counter++;
            } else {
                [self.taskArray removeObject:projectTask];
            }
        }
    } else {
        for (Task * projectTask in self.parentTask.subTasks) {
            if ([projectTask.level integerValue] == [self.parentTask.level integerValue] + 1) {
                counter++;
            } else {
                [self.taskArray removeObject:projectTask];
            }
        }
    }
    

    NSInteger retValue = counter;
    return retValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Task *task = [self.taskArray objectAtIndex:indexPath.row];
    static NSString *childCellIdentifier = @"childCell";
    static NSString *groupCellIdentifier = @"groupCell";
    
    UITableViewCell *cell = nil;
    
    if ([task.subTasks count] > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:groupCellIdentifier];
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"Sub-Task count: %u", [task.subTasks count]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:childCellIdentifier];
        cell.detailTextLabel.text = nil;
    }
    
    cell.textLabel.text = task.title;
    return cell;
}

#pragma mark - Action Sheet Functionality
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSMutableArray *newSubTasks = [[NSMutableArray alloc] init];
        float maxDisplay = 0;
        for (Task *ptask in self.gainingProject.projectTask) {
            if ([ptask.displayOrder floatValue] > maxDisplay) {
                maxDisplay = [ptask.displayOrder floatValue];
            }
        }
        maxDisplay = maxDisplay + 1;
        
        Task *task = self.selectedTask;
        Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
        newTask.completed = [NSNumber numberWithBool:NO];
        newTask.notes = task.notes;
        newTask.title = task.title;
        newTask.active = task.active;
        newTask.displayOrder = [NSNumber numberWithFloat:maxDisplay];
        newTask.visible = task.visible;
        newTask.level = task.level;
        newTask.type = task.type;
        if (task.superTask != nil) {
            newTask.superTask = task.superTask;
        }
        [self.gainingProject addProjectTaskObject:newTask];
        
        for (Task *cloneTask in self.selectedTask.subTasks) {
            // Put it in the super class
            Task *newSubTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
            newSubTask.completed = [NSNumber numberWithBool:NO];
            newSubTask.notes = cloneTask.notes;
            newSubTask.title = cloneTask.title;
            newSubTask.active = cloneTask.active;
            newSubTask.displayOrder = [NSNumber numberWithFloat:maxDisplay + 0.1f];
            newSubTask.visible = cloneTask.visible;
            newSubTask.level = cloneTask.level;
            newSubTask.type = cloneTask.type;
            newSubTask.superTask = newTask;
            [self.gainingProject addProjectTaskObject:newSubTask];
            [newSubTasks addObject:newSubTask];
        }
        
        NSSet *newTaskSet = [[NSSet alloc] initWithArray:newSubTasks];
        [newTask addSubTasks:newTaskSet];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - Table view delegate
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.driller.projectDelegate = self;
    self.selectedIndex = indexPath;
    [self.navigationController pushViewController:self.driller animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedTask = [self.taskArray objectAtIndex:indexPath.row];
    self.gainingProject = [self.projectDelegate getControllingProject];
    
    if (![self.gainingProject.projectName isEqualToString:self.donorProject.projectName]){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[[NSString alloc] initWithFormat:@"Add selected task(s) from %@ project to %@ project. NOTE: this will clone just the immediate sub-tasks of the selected task.", self.donorProject.projectName, self.gainingProject.projectName] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Append Tasks" otherButtonTitles:nil];
        CGRect rect = CGRectMake(0, 0, 320, 150);
        [actionSheet showFromRect:rect inView:self.parentViewController.view animated:YES];
    }
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)request{
    if (_request == nil) {
        _request = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    }
    return _request;
}

-(NSPredicate *)allPredicate{
    if (_allPredicate == nil) {
        NSString *filterProject = self.donorProject.projectName;
        _allPredicate = [NSPredicate predicateWithFormat:@"taskProject.projectName == %@ AND visible == YES", filterProject];
    }
    return _allPredicate;
}

-(CCAuxTaskCloneDrillController *)driller{
    if (_driller == nil) {
        _driller = [self.storyboard instantiateViewControllerWithIdentifier:@"cloneDrill"];
    }
    return _driller;
}


@end
