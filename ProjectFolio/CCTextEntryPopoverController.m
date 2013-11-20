//
//  CCTextEntryPopoverController.m
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCTextEntryPopoverController.h"
#import "CCSettingsControl.h"

@interface CCTextEntryPopoverController ()

@property (strong, nonatomic) CCSettingsControl *settings;

@end

@implementation CCTextEntryPopoverController

#pragma mark - Popover Controls

-(IBAction)savePressed:(id)sender{
    [self.delegate savePopoverData];
}

-(IBAction)cancelPressed:(id)sender{
    [self.delegate cancelPopover];
}

-(BOOL)shouldShowCancelButton{
    return YES;
}

#pragma mark View Controls

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated{
    self.textField.text = self.projectName;
    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.delegate = nil;
    self.textField = nil;
    self.projectName = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
