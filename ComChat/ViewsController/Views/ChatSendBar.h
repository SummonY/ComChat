//
//  ChatSendBar.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, ChatSendBarFunctionOptions) {
    ChatSendBarFunctionOption_Voice     = 1 << 0,
    ChatSendBarFunctionOption_Text      = 1 << 1,
    ChatSendBarFunctionOption_Emotion   = 1 << 2,
    ChatSendBarFunctionOption_More      = 1 << 3,
    ChatSendBarFunctionOption_All       = ChatSendBarFunctionOption_Voice | ChatSendBarFunctionOption_Text | ChatSendBarFunctionOption_Emotion | ChatSendBarFunctionOption_More
};


@protocol ChatSendBarDelegate;

@interface ChatSendBar : UIView

@property (nonatomic, weak) id<ChatSendBarDelegate> delegate;
@property (nonatomic, copy) NSString *inputText;
@property (nonatomic, assign) ChatSendBarFunctionOptions functionOptions;

- (id)initWithFunctionOptions:(ChatSendBarFunctionOptions)options;

- (void)insertEmotionName:(NSString *)emotionName;
- (BOOL)makeTextViewBecomeFirstResponder;
- (BOOL)makeTextViewResignFirstResponder;
- (void)clearInputTextView;
- (void)makeSendEnable;
- (void)deleteLastCharTextView;


@end


@protocol ChatSendBarDelegate <NSObject>

@optional

- (void)showEmotionView;
- (void)showShareMoreView;
- (void)showKeyboard;
- (void)showVoiceView;
- (void)sendPlainMessage:(NSString *)plainMessage;
- (void)didChangeHeight:(CGFloat)height;


@end
