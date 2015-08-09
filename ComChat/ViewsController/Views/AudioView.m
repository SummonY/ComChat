//
//  AudioView.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "AudioView.h"
#import "UIViewAdditions.h"
#import "AudioRecordPlayManager.h"
#import "XMPPManager.h"
#import "ChatViewModel.h"


@interface AudioView()

@property (nonatomic, strong) UILabel *voiceTitle;
@property (nonatomic, strong) UIButton *voiceBtn;

@end



@implementation AudioView


#pragma mark 初始化框架
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        // 初始化label
        self.voiceTitle = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 20)];
        self.voiceTitle.text = @"按住说话";
        self.voiceTitle.backgroundColor = [UIColor whiteColor];
        [self.voiceTitle setFont:[UIFont systemFontOfSize:15.f]];
        [self addSubview:self.voiceTitle];
        
        // 初始化button
        self.voiceBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, 140.f, 140.f)];
        [self.voiceBtn setBackgroundImage:[UIImage imageNamed:@"voice_bg_nor"] forState:UIControlStateNormal];
        [self.voiceBtn setBackgroundImage:[UIImage imageNamed:@"voice_bg_press"] forState:UIControlStateSelected];
        [self.voiceBtn setImage:[UIImage imageNamed:@"voice_nor"] forState:UIControlStateNormal];
        [self.voiceBtn setImage:[UIImage imageNamed:@"voice_press"] forState:UIControlStateSelected];
        [self.voiceBtn addTarget:self action:@selector(startRecordVoiceAction) forControlEvents:UIControlEventTouchDown];
        [self.voiceBtn addTarget:self action:@selector(stopRecordVoiceAction) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [self addSubview:self.voiceBtn];
        
        self.voiceTitle.center = CGPointMake(self.width / 2, 20);
        self.voiceBtn.top = self.voiceTitle.bottom;
        self.voiceBtn.center = CGPointMake(self.width / 2, self.voiceTitle.bottom + 10 + 70);
    }
    return self;
}


#pragma mark 开始记录声音
- (void)startRecordVoiceAction
{
    NSLog(@"开始记录声音,打开麦克风...");
    self.voiceTitle.text = @"录音中...";
    [[AudioRecordPlayManager sharedManager] startRecord];
}

#pragma mark 停止记录声音
- (void)stopRecordVoiceAction
{
    NSLog(@"停止记录声音，关闭麦克风...");
    self.voiceTitle.text = @"按住说话";
    
    [[AudioRecordPlayManager sharedManager] stopRecordSuccess:^(NSURL *url, NSTimeInterval time) {
        
        // 发送声音数据
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *voiceName = [url lastPathComponent];
        if (time > 0 && self.delegate && [self.delegate respondsToSelector:@selector(didFinishRecordingAudioWithUrlKey:data:time:)]) {
            [self.delegate didFinishRecordingAudioWithUrlKey:(NSString *)voiceName data:(NSData *)data time:(NSInteger)time];
        }
        /*
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishRecordingAudioWithData:bodyName:)]) {
            [self.delegate didFinishRecordingAudioWithData:data bodyName:[NSString stringWithFormat:@"%.1f秒", time]];
        }*/
        //NSData *data = [NSData dataWithContentsOfURL:url];
        //[[XMPPManager sharedManager] sendMessageWithData:data bodyName:[NSString stringWithFormat:@"audio:%.1f秒", time]];
        
    } andFailed:^{
        
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"时间太短" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    }];
    
    /*
    [[AudioRecordPlayManager sharedManager] stopRecordWithBlock:^(NSString *voiceName, NSData *voiceData, NSInteger time) {
        if (time > 0 && self.delegate && [self.delegate respondsToSelector:@selector(didFinishRecordingAudioWithUrlKey:data:time:)]) {
            [self.delegate didFinishRecordingAudioWithUrlKey:(NSString *)voiceName data:(NSData *)voiceData time:(NSInteger)time];
        }
    }];
     */
}


@end
