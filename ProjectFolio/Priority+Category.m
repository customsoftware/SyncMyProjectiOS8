//
//  Priority+Category.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 7/17/13.
//
//

#import "Priority+Category.h"

@implementation Priority (Category)

- (UIColor *)getCategoryColor
{
    UIColor *textColor = nil;
    if (self.color) {
        unsigned rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:self.color];
        [scanner scanHexInt:&rgbValue];
        int r = (rgbValue >> 16) & 0xFF;
        int g = (rgbValue >> 8) & 0xFF;
        int b = (rgbValue) & 0xFF;
        textColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    } else {
        textColor = [UIColor whiteColor];
    }
    return textColor;
}


@end
