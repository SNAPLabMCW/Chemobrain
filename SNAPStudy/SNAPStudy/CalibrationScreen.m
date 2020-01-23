//
//  CalibrationScreen.m
//  SNAPStudy
//
//  Created by Patryk Laurent on 8/24/14.
//  Copyright (c) 2014 faucetEndeavors. All rights reserved.
//

#import "CalibrationScreen.h"

@implementation CalibrationScreen

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 6);
    CGFloat dash[2]={6 ,5}; // pattern 6 times “solid”, 5 times “empty”
    CGContextSetLineDash(context,0,dash,2);
    CGContextSetStrokeColorWithColor(context,
                                     [UIColor whiteColor].CGColor);

    CGRect faceEllipse = rect;
    faceEllipse.origin.y = faceEllipse.origin.y + 90;
    faceEllipse.size.height = faceEllipse.size.height - 2*90;
    faceEllipse.origin.x += 50;
    faceEllipse.size.width -= 130;
    
    CGContextStrokeEllipseInRect(context, faceEllipse);

    
    CGRect leftEye = rect;
    leftEye.size.height = 60;
    leftEye.size.width = 100;
    leftEye.origin.x = faceEllipse.origin.x + 60;
    leftEye.origin.y = faceEllipse.origin.y + 190;
    CGContextStrokeEllipseInRect(context, leftEye);

    CGRect rightEye = rect;
    rightEye.size.height = leftEye.size.height;
    rightEye.size.width = leftEye.size.width;
    rightEye.origin.x = faceEllipse.size.width - 60 - rightEye.size.width + faceEllipse.origin.x;
    rightEye.origin.y = faceEllipse.origin.y + 190;
    CGContextStrokeEllipseInRect(context, rightEye);
    
    
    
    CGRect textRect = rect;
    textRect.origin.y += 200;
    [self drawText:@"Please ensure your head fills the circle." inRect:textRect];
}

- (void)drawText:(NSString*)text inRect:(CGRect)rect
{
    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    UIFont* font = [UIFont boldSystemFontOfSize:14.0f];
    NSDictionary* attributes = @{ NSFontAttributeName : font,
                                  NSParagraphStyleAttributeName : paragraphStyle };
    [text drawInRect:rect withAttributes:attributes];
}


@end
