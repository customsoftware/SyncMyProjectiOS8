//
//  CCInitializer.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/20/12.
//
//

#import "CCInitializer.h"
#define kInterval 730000

@implementation CCInitializer

-(Project *)addProjectWithName:(NSString *)projectName{
    Project *newProject = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newProject.projectName = projectName;
    newProject.dateCreated = [NSDate date];
    newProject.dateStart = newProject.dateCreated;
    newProject.dateFinish = [NSDate dateWithTimeInterval:kInterval sinceDate:newProject.dateCreated];
    newProject.active = [NSNumber numberWithBool:YES];
    return newProject;
}

-(Task *)addTaskWithTitle:(NSString *)projectName andNotes:(NSString *)notes toProject:(Project *)project{
    Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newTask.title = projectName;
    newTask.taskProject = project;
    newTask.notes = notes;
    newTask.level = [NSNumber numberWithInt:0];
    newTask.completed = [NSNumber numberWithBool:NO];
    [project addProjectTaskObject:newTask];
    
    return newTask;
}

-(void)addTaskWithTitle:(NSString *)projectName andNotes:(NSString *)notes toAnotherTask:(Task *)parentTask inProject:(Project *)project{
    Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newTask.title = projectName;
    newTask.notes = notes;
    newTask.taskProject = project;
    newTask.completed = [NSNumber numberWithBool:NO];
    newTask.visible = [NSNumber numberWithBool:NO];
    newTask.level = [NSNumber numberWithInt:1];
    [project addProjectTaskObject:newTask];
    newTask.superTask = parentTask;
    [parentTask addSubTasksObject:newTask];
}

-(void)createAnExpense:(NSString *)item forAmount:(NSNumber *)amount boughtFrom:(NSString *)vendor forProject:(Project *)project{
    Deliverables *newExpense = [NSEntityDescription insertNewObjectForEntityForName:@"Expense" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    newExpense.amount = amount;
    newExpense.paidTo = vendor;
    newExpense.pmtDescription = item;
    newExpense.expenseProject = project;
    newExpense.expensed = [NSNumber numberWithBool:NO];
    newExpense.datePaid = [NSDate dateWithTimeInterval:230000 sinceDate:[NSDate date]];
    newExpense.notes = @"Please click the sticky-notes button.    \nYou can also enter notes about the purchase.\nYou can take a photograph of your receipt by clicking on the camera button. If it's not enabled, it means your iOS device doesn't have a camera.\nYou can also use expences to track milage. You can do this one of two ways.\n1. You can directly enter the milage in the milage field.\n2. You can click on the airplane button to use location services to compute milage for you based upon your current location and the location you set as 'home' in the settings popover.";
    [project addProjectExpenseObject:newExpense];
}

-(NSString *)getNotes{
    NSMutableString *notes = [[NSMutableString alloc] initWithFormat:@"By navigating through the tasks and expenses of this project, you can learn how to use the application.\n\n"];
    [notes appendFormat:@"In the settings popover, tapping the 'Open on-Line Help' button will take you to the online FAQ that shows you how to use the advanced features of the app.\n\n"];
    [notes appendFormat:@"You can write notes about the project here.\n"];
    [notes appendFormat:@"You can convert your notes into tasks by writing notes such as these below:\n\n"];
    [notes appendFormat:@"Learn to use ProjectFolio\n"];
    [notes appendFormat:@"Take good notes\n"];
    [notes appendFormat:@"Turn notes into tasks\n"];
    [notes appendFormat:@"Get tasks done\n\n"];
    [notes appendFormat:@"Then selecting them and tapping on the 'Create Task' menu button\n\n"];
    [notes appendFormat:@"You can set the display font of these notes and notes on expenses and tasks in the settings popover.\n"];
    [notes appendFormat:@"You can also set font size and screen color in the settings popover\n\n"];
    [notes appendFormat:@"By clicking on the 'Home' button in the settings popover, you can set your 'home' location for computing miles traveled in the expenses popover.\n\n"];
    [notes appendFormat:@"You can set the default calendar the app will use to save meetings in and in which it will look for existing meetings to add to it's meeting list. It will search for meetings which have the name of the project embeded in the meeting title.\n\n"];
    [notes appendFormat:@"The 'line graph' button in the lower right will give you a graphic presentation of your active projects over time. The vertical red line in the chart represents today. Projects that are on time are green. Projects that are late are red. Projects that haven't started yet are gray.\n\n"];
    [notes appendFormat:@"The 'graph' button in the lower left will give you a graphic presentation of your active tasks over time. The vertical gray line in the chart represents today. Detail text for tasks that are late are red. Detail notes for completed tasks are green. The double red vertical lines are when the project is due. The black horizontal lines represent a super-task. Its sub-tasks are displayed under it.\n\n"];
    [notes appendFormat:@"The 'price tag' button in the lower left is where you enter expenses.\n\n"];
    [notes appendFormat:@"The 'calendar' button in the lower left is where you can create and edit meetings. Meetings created here are stored in your calendar application.\n\n"];
    [notes appendFormat:@"The 'stop watch' button in the lower left is where you review time spent on the project.\n\n"];
    
    
    return [[NSString alloc] initWithFormat:@"%@", notes];
}

-(void)loadTestData{
    // Get Project
    Project *mainProject = [self addProjectWithName:@"Sample Project"];
    mainProject.projectNotes = [self getNotes];
    
    // Make a couple of tasks & sub tasks
    Task *task = [self addTaskWithTitle:@"Super Task" andNotes:@"Enter notes here" toProject:mainProject];
    [self addTaskWithTitle:@"Sub-task sample" andNotes:@"Please tap the sticky-notes button.\nSome more notes\nYou can also create sub-tasks by entering bullet actions in the task's notes form. Select them, then tap the 'Create Task' menu\nYou can re-arrange task in edit mode. Note that you can't re-arrange sub-tasks, they are sorted by due date and move with the top-level task when you re-arrange the tasks.\n\nYou can also set due dates for tasks by clicking on the Due Date cell. This will display a date picker. Tasks which have a due date will display, sorted in order of when they are due, in the 'Hot List'. You select the Hot List when the projects are displayed at the bottom of the list. The far right button, with the lightning bolt, is the 'Hot List' button." toAnotherTask:task inProject:mainProject];
    [self addTaskWithTitle:@"Categories" andNotes:@"The category button, at the bottom of the Project list view and Hot List task view modifies the search functionality. The 'Category button' is the button with the wrench super imposed over a pencil. When this button is tapped, and you do a search, the category set for the project or the task is what the search runs against. For example, if you have a category of 'Medium' assigned to three of say ten projects and you tap the category button, then tap in the search bar and then type the letter 'M', just those three projects will remain in the list. If the button is not tapped, then just those projects that begin with the letter 'M' will appear in the result list." toProject:mainProject];
    
    // Enter a couple of expenses
    NSNumber *purchaseAmount = [NSNumber numberWithDouble:499.00];
    [self createAnExpense:@"iPad" forAmount:purchaseAmount boughtFrom:@"Apple Computer" forProject:mainProject];
    Project *earlyProject = [self addProjectWithName:@"Early Project"];
    earlyProject.dateStart = [NSDate dateWithTimeInterval:kInterval/2 sinceDate:[NSDate date]];
    earlyProject.dateFinish = [NSDate dateWithTimeInterval:kInterval/2 sinceDate:earlyProject.dateStart];;
    Project *lateProject = [self addProjectWithName:@"Late Project"];
    lateProject.dateStart = [NSDate dateWithTimeInterval:-kInterval sinceDate:[NSDate date]];
    lateProject.dateFinish = [NSDate dateWithTimeInterval:-24000 sinceDate:[NSDate date]];
    [[[CoreData sharedModel:nil] managedObjectContext] save:nil];
}
@end
