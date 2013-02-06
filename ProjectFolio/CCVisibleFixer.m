//
//  CCVisibleFixer.m
//  ProjectFolio
//
//  Created by Ken Cluff on 10/1/12.
//
//

#import "CCVisibleFixer.h"

@interface CCVisibleFixer ()

@property (strong, nonatomic) NSManagedObjectContext *context;


@end

@implementation CCVisibleFixer
@synthesize context = _context;


-(BOOL)fixAllVisible{
    BOOL retValue = YES;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    NSPredicate *allTasks   = [NSPredicate predicateWithFormat:@"visible != nil"];
    [request setPredicate:allTasks];
    NSSortDescriptor *rowOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects: rowOrderDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    NSFetchedResultsController * taskFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                       managedObjectContext:self.context
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    NSError *fetchError = [[NSError alloc] init];
    [taskFRC performFetch:&fetchError];
    
    for (Task *task in taskFRC.fetchedObjects) {
        if (task.superTask != nil) {
            task.visible = [NSNumber numberWithBool:NO];
        } else {
            task.visible = [NSNumber numberWithBool:YES];
            [task setLevelWith:[NSNumber numberWithInt:0]];
        }
    }
    
    return retValue;
}



-(NSManagedObjectContext *)context{
    if (_context == nil) {
        CCAppDelegate *application = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
        _context = application.managedObjectContext;
    }
    return _context;
}
@end
