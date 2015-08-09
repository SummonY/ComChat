//
//  JSCustomBadge.h
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

#import <UIKit/UIKit.h>

@interface JSCustomBadge : UIView

@property (strong, nonatomic) NSString *badgeText;
@property (strong, nonatomic) UIColor *badgeTextColor;
@property (strong, nonatomic) UIColor *badgeInsetColor;
@property (strong, nonatomic) UIColor *badgeFrameColor;

@property (assign, nonatomic) BOOL badgeFrame;
@property (assign, nonatomic) BOOL badgeShining;

@property (assign, nonatomic) CGFloat badgeCornerRoundness;
@property (assign, nonatomic) CGFloat badgeScaleFactor;

+ (JSCustomBadge *)customBadgeWithString:(NSString *)badgeString;

+ (JSCustomBadge *)customBadgeWithString:(NSString *)badgeString
                         withStringColor:(UIColor*)stringColor
                          withInsetColor:(UIColor*)insetColor
                          withBadgeFrame:(BOOL)badgeFrameYesNo
                     withBadgeFrameColor:(UIColor*)frameColor
                               withScale:(CGFloat)scale
                             withShining:(BOOL)shining;

// Use to change the badge text after the first rendering
- (void)autoBadgeSizeWithString:(NSString *)badgeString;

@end
