# JSCustomBadge

A simple, iOS badge UIView drawn with CoreGraphics.

![Badge Screenshot 1](https://raw.github.com/jessesquires/JSCustomBadge/master/Screenshots/screenshot.png)

## About

Original work by [Sascha Marc Paulus](http://www.spaulus.com).

Forked from [@ckteebe / CustomBadge](http://github.com/ckteebe/CustomBadge) — *which seems to have been abandoned*.

* Simple, easy-to-use sublcass of `UIView`
* Drawn with CoreGraphics, no images
* iOS 5.0+, ARC, Universal, Retina, Storyboards

## Installation

Drag the `JSCustomBadge/` folder to your project

## How To Use

Create a badge with either of the following methods:

````objective-c
+ (JSCustomBadge *)customBadgeWithString:(NSString *)badgeString

+ (JSCustomBadge *)customBadgeWithString:(NSString *)badgeString
                         withStringColor:(UIColor *)stringColor
                          withInsetColor:(UIColor *)insetColor
                          withBadgeFrame:(BOOL)badgeFrameYesNo
                     withBadgeFrameColor:(UIColor *)frameColor
                               withScale:(CGFloat)scale
                             withShining:(BOOL)shining
````

To change the badge text after the first rendering:

````objective-c
- (void)autoBadgeSizeWithString:(NSString *)badgeString
````

####See included demo project: `BadgeDemo.xcodeproj`

## [MIT License](http://opensource.org/licenses/MIT)

Copyright &copy; 2013 Jesse Squires

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
