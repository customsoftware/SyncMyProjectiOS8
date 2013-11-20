//
//  CCPopoverControllerDelegate.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@protocol CCPopoverControllerDelegate <NSObject>

-(IBAction)savePopoverData;
-(IBAction)cancelPopover;

@optional
-(BOOL)shouldShowCancelButton;
@end
