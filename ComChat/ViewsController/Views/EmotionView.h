//
//  EmotionView.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmotionDelegate;

@interface EmotionView : UIView

@property (nonatomic, weak) id<EmotionDelegate> emotionDelegate;

@end



@protocol EmotionDelegate <NSObject>

@optional

- (void)emotionSelectedWithName:(NSString*)name;
- (void)didEmotionViewDeleteAction;
- (void)didEmotionViewSendAction;


@end
