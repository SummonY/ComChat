//
//  ChatSendBar.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ChatSendBar.h"
#import "EmotionView.h"
#import "ChatShareMoreView.h"
#import "AudioView.h"
#import "UIViewAdditions.h"
#import <HPGrowingTextView.h>
#import "UIView+Toast.h"
#import "EmotionManager.h"
#import <AFNetworkReachabilityManager.h>


#define CHAT_INPUT_BAR_SIZE CGSizeMake([UIScreen mainScreen].bounds.size.width, 40.f)
#define KEYBOARD_HEIGHT     216.0f

#define BUTTON_TAG_VOICE    1000
#define BUTTON_TAG_KEYBOARD 1001
#define BUTTON_TAG_EMOTION  1002
#define BUTTON_TAG_MORE     1003


@interface ChatSendBar()<HPGrowingTextViewDelegate>

@property (nonatomic, strong) HPGrowingTextView *textView;
@property (nonatomic, strong) UIButton *emotionBtn;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) UIImageView *textViewBgView;
@property (nonatomic, strong) UIButton *voiceBtn;

@property (nonatomic, assign) BOOL isSendKeyTapped;
@property (nonatomic, assign) BOOL sendEnable;
@property (nonatomic, assign) NSRange nextlineRange;
@property (nonatomic, copy) NSString *inputMessage;
@property (nonatomic, assign) CGFloat lastViewHeight;
@property (nonatomic, assign) NSRange cusorRange;

@end



@implementation ChatSendBar

#pragma mark 操作初始化
- (id)initWithFunctionOptions:(ChatSendBarFunctionOptions)options
{
    if (self = [super initWithFrame:CGRectMake(0, 0, CHAT_INPUT_BAR_SIZE.width, CHAT_INPUT_BAR_SIZE.height)]) {
        self.functionOptions = options;
        
        /* 初始化底部发送条 */
        [self addSubview:self.emotionBtn];
        [self addSubview:self.moreBtn];
        [self addSubview:self.textView];
        [self addSubview:self.textViewBgView];
        [self addSubview:self.voiceBtn];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        // 初始化按钮tag
        self.voiceBtn.tag = BUTTON_TAG_VOICE;
        self.emotionBtn.tag = BUTTON_TAG_EMOTION;
        self.moreBtn.tag = BUTTON_TAG_MORE;
        
        self.isSendKeyTapped = NO;
        self.sendEnable = YES;
        self.lastViewHeight = self.height;
        self.cusorRange = NSMakeRange(0, 0);
        
        [self customLayoutSubviews];
    }
    return self;
}


#pragma mark 自定义布局子视图
- (void) customLayoutSubviews
{
    CGFloat keyViewWidth = CHAT_INPUT_BAR_SIZE.width;
    CGFloat keyViewHeight = CHAT_INPUT_BAR_SIZE.height;
    
    /* 设置按钮宽、高、边界 */
    CGFloat keyBtnWidth = 35.f;
    CGFloat keyBtnHeight = 35.f;
    CGFloat keyBtnTopMargin = (keyViewHeight - keyBtnHeight) / 2;
    
    /* 消息区大小 */
    CGFloat keyTextViewWidth = keyViewWidth;
    CGFloat keyTextViewBgMargin = 2.f;
    CGFloat keyTextViewMinHeight = 35.f;
    CGFloat keyTextViewMaxHeight = [UIScreen mainScreen].bounds.size.height - KEYBOARD_HEIGHT;                  // 待计算
    
    /* 设定表情按钮框架 */
    if (self.functionOptions & ChatSendBarFunctionOption_Emotion) {
        keyTextViewWidth = keyTextViewWidth - keyBtnWidth;
        self.emotionBtn.frame = CGRectMake(0.f, keyBtnTopMargin, keyBtnWidth, keyBtnHeight);
    } else {
        self.emotionBtn.frame = CGRectZero;
    }
    
    /* 设定更多按钮框架 */
    if (self.functionOptions & ChatSendBarFunctionOption_More) {
        keyTextViewWidth = keyTextViewWidth - keyBtnWidth;
        self.moreBtn.frame = CGRectMake(0.f, keyBtnTopMargin, keyBtnWidth, keyBtnHeight);
    } else {
        self.moreBtn.frame = CGRectZero;
    }
    
    /* 设定声音按钮框架 */
    if (self.functionOptions & ChatSendBarFunctionOption_Voice) {
        keyTextViewWidth = keyTextViewWidth - keyBtnWidth - 20;
        self.voiceBtn.frame = CGRectMake(0.f, keyBtnTopMargin, keyBtnWidth + 20, keyBtnHeight);
    } else {
        self.voiceBtn.frame = CGRectZero;
    }
    
    if (self.functionOptions & ChatSendBarFunctionOption_Text) {
        self.textViewBgView.frame = CGRectMake(self.moreBtn.right, keyTextViewBgMargin, keyTextViewWidth, keyViewHeight - keyTextViewBgMargin * 2);
        self.textView.frame = CGRectMake(self.moreBtn.right, keyBtnTopMargin, keyTextViewWidth, keyTextViewMinHeight);
        self.textView.minHeight = keyTextViewMinHeight;
        self.textView.maxHeight = keyTextViewMaxHeight;
    } else {
        self.textViewBgView.frame = CGRectZero;
        self.textView.frame = CGRectZero;
    }
    
    self.moreBtn.left = self.emotionBtn.right;
    self.textViewBgView.left = self.moreBtn.right;
    self.textView.left = self.moreBtn.right;
    self.voiceBtn.left = self.textView.right;
}

#pragma mark 绘制形状
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    UIColor *boardLineColor = [UIColor grayColor];
    
    // 设置背景
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0.5f, rect.size.height - 0.5f, rect.size.width, rect.size.height - 1.f));
    
    CGContextSetStrokeColorWithColor(ctx, [boardLineColor CGColor]);
    CGContextBeginPath(ctx);
    
    /* 设置顶部和底部线条 */
    CGContextSetLineWidth(ctx, 0.5f);
    CGContextMoveToPoint(ctx, 0.f, 0.5f);
    CGContextAddLineToPoint(ctx, rect.size.width, 0.5f);
    
    CGContextMoveToPoint(ctx, 0.f, rect.size.height - 0.5f);
    CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height - 0.5f);
    CGContextDrawPath(ctx, kCGPathStroke);
}


#pragma mark 检查输入是否合法
- (BOOL)checkInputTextValid:(NSString *)intputText
{
    if (intputText.length > 0 && ![intputText isEqualToString:@"\n"]) {
        return YES;
    }
    return NO;
}

#pragma mark 滚动到底部
- (void)scrollToBottomAnimated:(BOOL)animated
{
    [self.textView.internalTextView scrollRectToVisible:
     CGRectMake(0.f,
                self.textView.internalTextView.contentSize.height - self.textView.internalTextView.height,
                self.textView.internalTextView.width,
                self.textView.internalTextView.height)
                                               animated:animated];
}

#pragma mark 插入表情名字
- (void)insertEmotionName:(NSString *)emotionName
{
    if (self.cusorRange.location > self.textView.text.length) {
        self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, emotionName];
    }
    else {
        NSMutableString *text = [NSMutableString stringWithString:self.textView.text];
        [text insertString:emotionName atIndex:self.cusorRange.location];
        self.textView.text = text;
    }
    
    self.cusorRange = NSMakeRange(self.cusorRange.location + emotionName.length,
                                  self.cusorRange.length + emotionName.length);
    
    if (self.textView.internalTextView.contentSize.height > self.textView.maxHeight) {
        [self scrollToBottomAnimated:YES];
    }
}

#pragma mark 删除最后一个字符
- (void)deleteLastCharTextView
{
    if (self.textView.text.length > 0) {
        NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
        BOOL success =
        [[EmotionManager sharedManager] deleteEmotionInTextView:self.textView.internalTextView
                                                          atRange:range];
        if (success) {
            
        }
        else {
            self.textView.text = [self.textView.text substringToIndex:self.textView.text.length - 1];
        }
        [self.textView refreshHeight];
    }
}


#pragma mark 取消第一响应
- (BOOL)makeTextViewResignFirstResponder
{
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
        return YES;
    }
    return NO;
}

#pragma mark 使其成为第一响应
- (BOOL)makeTextViewBecomeFirstResponder
{
    if (!self.textView.isFirstResponder) {
        [self.textView becomeFirstResponder];
        return YES;
    }
    return NO;
}


#pragma mark 获取输入框文本
- (NSString *)inputText
{
    return self.textView.text;
}

#pragma mark 设置输入框文本
- (void)setInputText:(NSString *)text
{
    self.textView.text = text;
}

#pragma mark 清除输入框文本
- (void)clearInputTextView
{
    self.textView.text = @"";
}

#pragma mark 使能发送按钮
- (void)makeSendEnable
{
    self.sendEnable = YES;
}


////////////////////////////////////////////////////////////////
#pragma mark ChatSendBar Delegate
////////////////////////////////////////////////////////////////


#pragma mark 声音和键盘之间切换
- (void)switchVoiceWithKeyboard
{
    if (self.voiceBtn.tag == BUTTON_TAG_VOICE) {
        // 切换到声音输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showVoiceView)]) {
            [self.delegate showVoiceView];
        }
        
        self.lastViewHeight = self.height;      //use to voice
        [self.textView resignFirstResponder];
        self.voiceBtn.tag = BUTTON_TAG_KEYBOARD;
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor"]
                               forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_press"]
                               forState:UIControlStateHighlighted];
    }
    else {
        // 切换到键盘输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showKeyboard)]) {
            [self.delegate showKeyboard];
        }
        
        self.height = self.lastViewHeight;          //use to voice
        
        [self.textView becomeFirstResponder];
        self.voiceBtn.tag = BUTTON_TAG_VOICE;
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"]
                               forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_press"]
                               forState:UIControlStateHighlighted];
    }
    
    // 重置表情按钮
    if (self.emotionBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.emotionBtn.tag = BUTTON_TAG_EMOTION;
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"]
                                 forState:UIControlStateNormal];
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"]
                                 forState:UIControlStateHighlighted];
    }
    
    // 重置分享按钮
    if (self.moreBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.moreBtn.tag = BUTTON_TAG_MORE;
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"]
                         forState:UIControlStateNormal];
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"]
                         forState:UIControlStateHighlighted];
    }
}


#pragma mark 表情按钮和键盘按钮之间切换
- (void)switchEmotionWithKeyboard
{
    if (self.emotionBtn.tag == BUTTON_TAG_EMOTION) {
        
        // 切换到表情输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showEmotionView)]) {
            [self.delegate showEmotionView];
        }
        
        self.height = self.lastViewHeight;
        self.cusorRange = self.textView.internalTextView.selectedRange;
        [self.textView resignFirstResponder];
        
        self.emotionBtn.tag = BUTTON_TAG_KEYBOARD;
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor"]
                                 forState:UIControlStateNormal];
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_press"]
                                 forState:UIControlStateHighlighted];
    }
    else {
        // 切换到键盘输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showKeyboard)]) {
            [self.delegate showKeyboard];
        }
        
        [self.textView becomeFirstResponder];
        
        self.emotionBtn.tag = BUTTON_TAG_EMOTION;
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"]
                                 forState:UIControlStateNormal];
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_press"]
                                 forState:UIControlStateHighlighted];
    }
    
    // 重置声音按钮
    if (self.voiceBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.voiceBtn.tag = BUTTON_TAG_VOICE;
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"]
                               forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_press"]
                               forState:UIControlStateHighlighted];
    }
    
    // 重置分享按钮
    if (self.moreBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.moreBtn.tag = BUTTON_TAG_MORE;
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"]
                       forState:UIControlStateNormal];
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_press"]
                       forState:UIControlStateHighlighted];
    }
}

#pragma mark 分享更多与键盘之间切换
- (void)switchMoreWithKeyboard
{
    NSLog(@"分享更多与键盘之间切换...");
    if (self.moreBtn.tag == BUTTON_TAG_MORE) {
        // 切换到表情输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showShareMoreView)]) {
            [self.delegate showShareMoreView];
        }
        
        self.lastViewHeight = self.height;          //use to shareMore
        [self.textView resignFirstResponder];
        self.moreBtn.tag = BUTTON_TAG_KEYBOARD;
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor"]
                      forState:UIControlStateNormal];
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_keyboard_press"]
                      forState:UIControlStateHighlighted];
    }
    
    else {
        // 切换到键盘输入
        if (self.delegate && [self.delegate respondsToSelector:@selector(showKeyboard)]) {
            [self.delegate showKeyboard];
        }
        
        self.height = self.lastViewHeight;          //use to shareMore
        [self.textView becomeFirstResponder];
        self.moreBtn.tag = BUTTON_TAG_MORE;
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"]
                       forState:UIControlStateNormal];
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_press"]
                       forState:UIControlStateHighlighted];
    }
    
    // 重置表情按钮
    if (self.emotionBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.emotionBtn.tag = BUTTON_TAG_EMOTION;
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"]
                         forState:UIControlStateNormal];
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"]
                         forState:UIControlStateHighlighted];
    }
    
    // 重置声音按钮
    if (self.voiceBtn.tag == BUTTON_TAG_KEYBOARD) {
        self.voiceBtn.tag = BUTTON_TAG_VOICE;
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateHighlighted];
    }
    
}


////////////////////////////////////////////////////////////////
#pragma mark HPGrowingTextViewDelegate
////////////////////////////////////////////////////////////////

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView
{
    // 表情
    if (BUTTON_TAG_KEYBOARD == self.emotionBtn.tag) {
        self.emotionBtn.tag = BUTTON_TAG_EMOTION;
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"] forState:UIControlStateNormal];
        [self.emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_press"] forState:UIControlStateHighlighted];
        
    }
    
    // 声音
    if (BUTTON_TAG_KEYBOARD == self.voiceBtn.tag) {
        self.voiceBtn.tag = BUTTON_TAG_VOICE;
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
        
    }
    
    // 分享
    if (BUTTON_TAG_KEYBOARD == self.moreBtn.tag) {
        self.moreBtn.tag = BUTTON_TAG_MORE;
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"] forState:UIControlStateNormal];
        [self.moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_press"] forState:UIControlStateHighlighted];
        
    }
    
    return YES;
}


- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView
{
    return YES;
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        self.nextlineRange = range;
        if (self.sendEnable) {
            //if ([AFNetworkReachabilityManager sharedManager].isReachable) {
                if ([self checkInputTextValid:growingTextView.text]) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(sendPlainMessage:)]) {
                        [self.delegate sendPlainMessage:self.textView.text];
                        self.sendEnable = NO;
                    }
                }
            //}
            //else {                                                                                  // TODO:可以发，直到有网络自动发送出去
            //    [self makeToast:@"网络不可达,发送失败" duration:1.0 position:CSToastPositionCenter];
            //}
        }
        return NO;
    }
    if (0 == text.length) {
        BOOL success = [[EmotionManager sharedManager] deleteEmotionInTextView:growingTextView.internalTextView atRange:range];
        if (success) {
            [growingTextView refreshHeight];
            return NO;
        }
    }
    
    return YES;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect r = self.frame;
    r.size.height -= diff;
    r.origin.y += diff;
    self.frame = r;
    
    self.lastViewHeight = self.height;
}


- (void)growingTextView:(HPGrowingTextView *)growingTextView didChangeHeight:(float)height
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeHeight:)]) {
        [self.delegate didChangeHeight:height];
    }
    if (self.textView.internalTextView.contentSize.height > self.textView.maxHeight) {
        [self scrollToBottomAnimated:YES];
    }
}

////////////////////////////////////////////////////////////////
#pragma mark UI Create
////////////////////////////////////////////////////////////////

- (HPGrowingTextView *)textView
{
    if (!_textView) {
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        _textView = [[HPGrowingTextView alloc] initWithFrame:CGRectZero];
        _textView.isScrollable = NO;
        _textView.contentInset = edgeInsets;
        _textView.internalTextView.scrollIndicatorInsets = edgeInsets;
        _textView.internalTextView.enablesReturnKeyAutomatically = YES;
        
        _textView.animateHeightChange = YES;
        _textView.animationDuration = 0.2f;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.font = [UIFont systemFontOfSize:15.f];
        _textView.backgroundColor = [UIColor whiteColor];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _textView.delegate = self;
    }
    return _textView;
}

#pragma mark 设置表情按钮
- (UIButton *)emotionBtn
{
    if (!_emotionBtn) {
        _emotionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_nor"] forState:UIControlStateNormal];
        [_emotionBtn setImage:[UIImage imageNamed:@"chat_bottom_emotion_press"] forState:UIControlStateHighlighted];
        [_emotionBtn addTarget:self action:@selector(switchEmotionWithKeyboard) forControlEvents:UIControlEventTouchUpInside];
        _emotionBtn.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        _emotionBtn.tag = BUTTON_TAG_EMOTION;
    }
    return _emotionBtn;
}

#pragma mark 设置更多按钮
- (UIButton *)moreBtn
{
    if (!_moreBtn) {
        _moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_nor"] forState:UIControlStateNormal];
        [_moreBtn setImage:[UIImage imageNamed:@"chat_bottom_more_press"] forState:UIControlStateHighlighted];
        [_moreBtn addTarget:self action:@selector(switchMoreWithKeyboard) forControlEvents:UIControlEventTouchUpInside];
        _moreBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _moreBtn.tag = BUTTON_TAG_MORE;
    }
    return _moreBtn;
}

#pragma mark 设置输入框
- (UIImageView *)textViewBgView
{
    if (!_textViewBgView) {
        UIImage *textViewBg = [UIImage imageNamed:@"chat_bottom_bg"];
        _textViewBgView = [[UIImageView alloc] initWithImage:[textViewBg stretchableImageWithLeftCapWidth:textViewBg.size.width / 2 topCapHeight:textViewBg.size.height / 2]];
        _textViewBgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _textViewBgView;
}

#pragma mark 设置语音按钮
- (UIButton *)voiceBtn
{
    if (!_voiceBtn) {
        _voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_nor"] forState:UIControlStateNormal];
        [_voiceBtn setImage:[UIImage imageNamed:@"chat_bottom_voice_press"] forState:UIControlStateHighlighted];
        [_voiceBtn addTarget:self action:@selector(switchVoiceWithKeyboard) forControlEvents:UIControlEventTouchUpInside];
        _voiceBtn.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        _voiceBtn.tag = BUTTON_TAG_VOICE;
        self.voiceBtn = _voiceBtn;
    }
    return _voiceBtn;
}


@end
