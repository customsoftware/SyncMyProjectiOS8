//
//  CCPeopleViewController.h
//  ProjectFolio
//
//  Created by Ken Cluff on 8/15/12.
//
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "Contact.h"
#import "CCPeopleDetailsViewController.h"
#import "CCAppDelegate.h"

@interface CCPeopleViewController : UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Project *project;
@property (strong, nonatomic) Contact *activeContact;
@property (strong, nonatomic) CCPeopleDetailsViewController *childController;

@end
