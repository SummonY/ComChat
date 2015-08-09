//
//  JSCustomBadge.m
//
//
//  Original work by Sascha Marc Paulus
//  Copyright (c) 2011
//  https://github.com/ckteebe/CustomBadge
//  http://www.spaulus.com
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//
//  http://www.hexedbits.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
//  associated documentation files (the "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
//  following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "JSCustomBadge.h"

@interface JSCustomBadge()

- (id)initWithString:(NSString *)badgeString withScale:(CGFloat)scale withShining:(BOOL)shining;

- (id)initWithString:(NSString *)badgeString
     withStringColor:(UIColor *)stringColor
      withInsetColor:(UIColor *)insetColor
      withBadgeFrame:(BOOL)badgeFrameYesNo
 withBadgeFrameColor:(UIColor *)frameColor
           withScale:(CGFloat)scale
         withShining:(BOOL)shining;

- (void)drawRoundedRectWithContext:(CGContextRef)context inRect:(CGRect)rect;
- (void)drawShineWithContext:(CGContextRef)context inRect:(CGRect)rect;
- (void)drawFrameWithContext:(CGContextRef)context inRect:(CGRect)rect;

@end



@implementation JSCustomBadge

#pragma mark - Initialization
- (id)initWithString:(NSString *)badgeString withScale:(CGFloat)scale withShining:(BOOL)shining
{
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
    
	if(self) {
		self.contentScaleFactor = [[UIScreen mainScreen] scale];
		self.backgroundColor = [UIColor clearColor];
		self.badgeText = badgeString;
		self.badgeTextColor = [UIColor whiteColor];
		self.badgeFrame = YES;
		self.badgeFrameColor = [UIColor whiteColor];
		self.badgeInsetColor = [UIColor redColor];
		self.badgeCornerRoundness = 0.4f;
		self.badgeScaleFactor = scale;
		self.badgeShining = shining;
		[self autoBadgeSizeWithString:badgeString];		
	}
    
	return self;
}

- (id)initWithString:(NSString *)badgeString
     withStringColor:(UIColor *)stringColor
      withInsetColor:(UIColor *)insetColor
      withBadgeFrame:(BOOL)badgeFrameYesNo
 withBadgeFrameColor:(UIColor *)frameColor
           withScale:(CGFloat)scale
         withShining:(BOOL)shining
{
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
    
	if(self) {
		self.contentScaleFactor = [[UIScreen mainScreen] scale];
		self.backgroundColor = [UIColor clearColor];
		self.badgeText = badgeString;
		self.badgeTextColor = stringColor;
		self.badgeFrame = badgeFrameYesNo;
		self.badgeFrameColor = frameColor;
		self.badgeInsetColor = insetColor;
		self.badgeCornerRoundness = 0.4f;
		self.badgeScaleFactor = scale;
		self.badgeShining = shining;
		[self autoBadgeSizeWithString:badgeString];
	}
    
	return self;
}

#pragma mark - Class initializers
+ (JSCustomBadge *) customBadgeWithString:(NSString *)badgeString
{
	return [[JSCustomBadge alloc] initWithString:badgeString withScale:1.0f withShining:YES];
}

+ (JSCustomBadge *) customBadgeWithString:(NSString *)badgeString
                          withStringColor:(UIColor *)stringColor
                           withInsetColor:(UIColor *)insetColor
                           withBadgeFrame:(BOOL)badgeFrameYesNo
                      withBadgeFrameColor:(UIColor *)frameColor
                                withScale:(CGFloat)scale
                              withShining:(BOOL)shining
{
	return [[JSCustomBadge alloc] initWithString:badgeString
                                 withStringColor:stringColor
                                  withInsetColor:insetColor
                                  withBadgeFrame:badgeFrameYesNo
                             withBadgeFrameColor:frameColor
                                       withScale:scale
                                     withShining:shining];
}

#pragma mark - Utilities
- (void)autoBadgeSizeWithString:(NSString *)badgeString
{
	CGSize retValue;
	CGFloat rectWidth, rectHeight;
	CGSize stringSize = [badgeString sizeWithFont:[UIFont boldSystemFontOfSize:12.0f]];
	CGFloat flexSpace;
	
    if([badgeString length] >= 2.0f) {
		flexSpace = [badgeString length];
		rectWidth = 25.0f + (stringSize.width + flexSpace); rectHeight = 25.0f;
		retValue = CGSizeMake(rectWidth * self.badgeScaleFactor, rectHeight * self.badgeScaleFactor);
	}
    else {
		retValue = CGSizeMake(25.0f * self.badgeScaleFactor, 25.0f * self.badgeScaleFactor);
	}
	
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, retValue.width, retValue.height);
	self.badgeText = badgeString;
	
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
	[self drawRoundedRectWithContext:context inRect:rect];
	
	if(self.badgeShining)
		[self drawShineWithContext:context inRect:rect];
	
	if(self.badgeFrame)
		[self drawFrameWithContext:context inRect:rect];
	
	if([self.badgeText length] > 0.0f) {
        
		[self.badgeTextColor set];
		CGFloat sizeOfFont = 13.5f * self.badgeScaleFactor;
		
        if([self.badgeText length] < 2.0f) {
			sizeOfFont += sizeOfFont * 0.2f;
		}
        
		UIFont *textFont = [UIFont boldSystemFontOfSize:sizeOfFont];
		CGSize textSize = [self.badgeText sizeWithFont:textFont];
		
        [self.badgeText drawAtPoint:CGPointMake((rect.size.width/2.0f - textSize.width/2.0f),
                                                (rect.size.height/2.0f - textSize.height/2.0f))
                           withFont:textFont];
	}
}

- (void)drawRoundedRectWithContext:(CGContextRef)context inRect:(CGRect)rect
{
	CGContextSaveGState(context);
	
	CGFloat radius = CGRectGetMaxY(rect) * self.badgeCornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * 0.1f;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
		
    CGContextBeginPath(context);
	CGContextSetFillColorWithColor(context, [self.badgeInsetColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2.0f), 0.0f, 0.0f);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0.0f, M_PI/2.0f, 0.0f);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2.0f, M_PI, 0.0f);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2.0f, 0.0f);
    
    CGContextSetShadowWithColor(context,
                                CGSizeMake(0.0f, 1.0f),
                                2.0f,
                                [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    
    CGContextFillPath(context);

	CGContextRestoreGState(context);
}

- (void)drawShineWithContext:(CGContextRef)context inRect:(CGRect)rect
{
	CGContextSaveGState(context);
 
	CGFloat radius = CGRectGetMaxY(rect) * self.badgeCornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * 0.1f;
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
    
	CGContextBeginPath(context);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI+(M_PI/2.0f), 0.0f, 0.0f);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0.0f, M_PI/2.0f, 0.0f);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2.0f, M_PI, 0.0f);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2.0f, 0.0f);
	CGContextClip(context);
	
	size_t num_locations = 2.0f;
	CGFloat locations[2] = { 0.0f, 0.4f };
	CGFloat components[8] = { 0.92f, 0.92f, 0.92f, 1.0f, 0.82f, 0.82f, 0.82f, 0.4f };

	CGColorSpaceRef cspace;
	CGGradientRef gradient;
	cspace = CGColorSpaceCreateDeviceRGB();
	gradient = CGGradientCreateWithColorComponents(cspace, components, locations, num_locations);
	
	CGPoint sPoint, ePoint;
	sPoint.x = 0.0f;
	sPoint.y = 0.0f;
	ePoint.x = 0.0f;
	ePoint.y = maxY;
	CGContextDrawLinearGradient (context, gradient, sPoint, ePoint, 0.0f);
	
	CGColorSpaceRelease(cspace);
	CGGradientRelease(gradient);
	
	CGContextRestoreGState(context);	
}

- (void)drawFrameWithContext:(CGContextRef)context inRect:(CGRect)rect
{
	CGFloat radius = CGRectGetMaxY(rect) * self.badgeCornerRoundness;
	CGFloat puffer = CGRectGetMaxY(rect) * 0.1f;
	
	CGFloat maxX = CGRectGetMaxX(rect) - puffer;
	CGFloat maxY = CGRectGetMaxY(rect) - puffer;
	CGFloat minX = CGRectGetMinX(rect) + puffer;
	CGFloat minY = CGRectGetMinY(rect) + puffer;
	
    CGContextBeginPath(context);
	CGFloat lineSize = 2.0f;
    
	if(self.badgeScaleFactor > 1.0f) {
		lineSize += self.badgeScaleFactor * 0.25f;
	}
    
	CGContextSetLineWidth(context, lineSize);
	CGContextSetStrokeColorWithColor(context, [self.badgeFrameColor CGColor]);
	CGContextAddArc(context, maxX-radius, minY+radius, radius, M_PI + (M_PI/2.0f), 0.0f, 0.0f);
	CGContextAddArc(context, maxX-radius, maxY-radius, radius, 0.0f, M_PI/2.0f, 0.0f);
	CGContextAddArc(context, minX+radius, maxY-radius, radius, M_PI/2.0f, M_PI, 0.0f);
	CGContextAddArc(context, minX+radius, minY+radius, radius, M_PI, M_PI+M_PI/2.0f, 0.0f);
	
    CGContextClosePath(context);
	CGContextStrokePath(context);
}

@end