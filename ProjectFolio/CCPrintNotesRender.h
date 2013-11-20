//
//  CCPrintNotesRender.h
//  SyncMyProject
//
//  Created by Kenneth Cluff on 3/4/13.
//
//

#import <UIKit/UIKit.h>

@interface CCPrintNotesRender : UIPrintPageRenderer

@property (strong, nonatomic) NSString *fontName;
@property (nonatomic) CGFloat fontSize;
@property (strong, nonatomic) NSString *headerString;

@end
