//
//  CCPopoverControllerDelegate.h
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CCPopoverControllerDelegate <NSObject>

-(IBAction)savePopoverData;
-(IBAction)cancelPopover;

@optional
-(BOOL)shouldShowCancelButton;
@end
