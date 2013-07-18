//
//  CCCategoryTaskViewController.m
//  ProjectFolio
//
//  Created by Ken Cluff on 11/22/12.
//
//

#import "CCCategoryTaskViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CCCategoryTaskViewController ()

@property (strong, nonatomic) Priority *currentCategory;
@property (strong, nonatomic) NSFetchedResultsController *categoryFRC;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;


@end

@implementation CCCategoryTaskViewController
@synthesize categoryDelegate = _categoryDelegate;
@synthesize currentCategory = _currentCategory;
@synthesize categoryFRC = _categoryFRC;
@synthesize fetchRequest = _fetchRequest;

-(IBAction)cancelCategory:(id)sender{
    [self.categoryDelegate saveSelectedCategory:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Priority" inManagedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]];
    NSSortDescriptor *categoryDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: categoryDescriptor, nil];
    [self.fetchRequest setSortDescriptors:sortDescriptors];
    [self.fetchRequest setEntity:entity];
    // [self.fetchRequest setPredicate:self.allPredicate];
    
    self.categoryFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                       managedObjectContext:[[CoreData sharedModel:nil] managedObjectContext]
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    
    // self.categoryFRC.delegate = self;
    NSError *fetchError = nil;
    [self.categoryFRC performFetch:&fetchError];
}

- (void)viewDidUnload
{
    self.categoryDelegate = nil;
    self.currentCategory = nil;
    self.categoryFRC = nil;
    self.fetchRequest = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentCategory = [self.categoryDelegate getCurrentCategory];
    
    if (self.currentCategory != nil) {
        NSIndexPath *indexPath = [self.categoryFRC indexPathForObject:self.currentCategory];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
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
    return [[self.categoryFRC fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Priority *priority = [self.categoryFRC objectAtIndexPath:indexPath];
    static NSString *CellIdentifier = @"categoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    UIView *catColor = [[UIView alloc] initWithFrame:CGRectMake(250, 5, 44, 34)];
    catColor.backgroundColor = [priority getCategoryColor];
    catColor.layer.cornerRadius = 3;
    catColor.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    catColor.layer.borderWidth = 1;
    [cell addSubview:catColor];
    cell.textLabel.text = priority.priority;
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Priority *priority = [self.categoryFRC objectAtIndexPath:indexPath];
    [self.categoryDelegate saveSelectedCategory:priority];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Lazy Getters
-(NSFetchRequest *)fetchRequest{
    if (_fetchRequest == nil) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

@end
