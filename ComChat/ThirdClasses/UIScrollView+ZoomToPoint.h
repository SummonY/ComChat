
//copy from here: https://gist.github.com/TimOliver/6138097
#import <UIKit/UIKit.h>

@interface UIScrollView (ZoomToPoint)

- (void)zoomToPoint:(CGPoint)zoomPoint withScale: (CGFloat)scale animated: (BOOL)animated;

@end