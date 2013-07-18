//
//  CCPrintNotesRender.m
//  ProjectFolio
//
//  Created by Kenneth Cluff on 3/4/13.
//
//

#import "CCPrintNotesRender.h"

@implementation CCPrintNotesRender
static inline CGFloat EdgeInset(CGFloat imageableAreaMargin)
{
    /*
     Because the offsets specified to a print formatter are relative to printRect and we want our edges to be at least MIN_MARGIN from the edge of the sheet of paper, here we compute the necessary offset to achieve our margin. If the imageable area margin is larger than our MIN_MARGIN, we return an offset of zero which means that the imageable area margin will be used.
     */
    CGFloat val = MIN_MARGIN - imageableAreaMargin;
    return val > 0 ? val : 0;
}

static CGFloat HeaderFooterHeight(CGFloat imageableAreaMargin, CGFloat textHeight)
{
    /*
     Make the header and footer height provide for a minimum margin of MIN_MARGIN. We want the content to appear at least MIN_HEADER_FOOTER_DISTANCE_FROM_CONTENT from the header/footer text. If that requires a margin > MIN_MARGIN then we'll use that. Remember, the header/footer height returned needs to be relative to the edge of the imageable area.
     */
    CGFloat headerFooterHeight = imageableAreaMargin + textHeight +
    MIN_HEADER_FOOTER_DISTANCE_FROM_CONTENT + HEADER_FOOTER_MARGIN_PADDING;
    if(headerFooterHeight < MIN_MARGIN)
        headerFooterHeight = MIN_MARGIN - imageableAreaMargin;
    else {
        headerFooterHeight -= imageableAreaMargin;
    }
    
    return headerFooterHeight;
}

- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)headerRect{
    UIFont *printFont = [UIFont fontWithName:self.fontName size:kFontPointSize];
    CGSize titleSize = [self.headerString sizeWithFont:printFont];
    CGFloat drawX = CGRectGetMaxX(headerRect)/2 - titleSize.width/2;
    CGFloat drawY = CGRectGetMaxY(headerRect) - titleSize.height;
    CGPoint drawPoint = CGPointMake(drawX, drawY);
    [self.headerString drawAtPoint:drawPoint withFont:printFont];
}

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)footerRect{
    UIFont *printFont = [UIFont fontWithName:self.fontName size:kFontPointSize];
    NSString *pageNumber = [NSString stringWithFormat:@"Page: %d", pageIndex + 1];
    CGSize pageNumSize = [pageNumber sizeWithFont:printFont];
    CGFloat drawX = CGRectGetMaxX(footerRect)/2 - pageNumSize.width - 1.0;
    CGFloat drawY = CGRectGetMaxY(footerRect) - pageNumSize.height;
    CGPoint drawPoint = CGPointMake(drawX, drawY);
    [pageNumber drawAtPoint:drawPoint withFont:printFont];
}

- (NSInteger)numberOfPages{
    UIPrintFormatter *formatter = (UIPrintFormatter *)self.printFormatters[0];
    CGFloat leftInset = EdgeInset(self.paperRect.origin.x);
    CGFloat rightInset = EdgeInset(self.paperRect.size.width - CGRectGetMaxX(self.printableRect));
    formatter.contentInsets = UIEdgeInsetsMake(0, leftInset, 0, rightInset);
    
    UIFont *printFont = [UIFont fontWithName:self.fontName size:kFontPointSize];
    CGFloat titleHeight = [self.headerString sizeWithFont:printFont].height;
    
    self.headerHeight = HeaderFooterHeight(CGRectGetMinY(self.printableRect), titleHeight);
    self.footerHeight = HeaderFooterHeight(self.paperRect.size.height - CGRectGetMaxY(self.printableRect), titleHeight);
    
    formatter.maximumContentHeight = self.paperRect.size.height - ( 2 * MIN_MARGIN);
    formatter.maximumContentWidth = self.paperRect.size.width - ( 2 * MIN_MARGIN);
    
    return [super numberOfPages];
}
@end
