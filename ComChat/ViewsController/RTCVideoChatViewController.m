//
//  RTCVideoChatViewController.m
//  ComChat
//
//  Created by D404 on 15/6/25.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RTCVideoChatViewController.h"
#import "UIViewAdditions.h"
/*
#import "RTCManager.h"
#import <RTCMediaStream.h>
#import <RTCVideoTrack.h>
#import <RTCVideoRenderer.h>
#import "ModalAlert.h"

@interface RTCVideoChatViewController () <RTCManagerDelegate>


@property (nonatomic, strong) RTCVideoTrack *videoTrack;

@end
*/
@implementation RTCVideoChatViewController

#pragma mark 初始化
- (instancetype)initWithUserJid:(NSString *)userJID
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.userJid = userJID;
    }
    return self;
}


- (void)dealloc
{
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频通话";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 添加Tap用来显示/隐藏控制器
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    /*
    [self.localView setDelegate:self];
    [self.remoteView setDelegate:self];
    
    // 开始RTC任务
    [[RTCManager sharedManager] startRTCTaskAsInitiator:YES withTarget:self.userJid];
     */
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}



#pragma mark 显示控制面板
- (void)toggleButtonContainer
{
    NSLog(@"点击显示控制面板...");

    [UIView animateWithDuration:0.5f animations:^ {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        
        if (self.hangUpBtn.top >= screenSize.height + 30) {
            self.hangUpBtn.top = screenSize.height - 20;
        } else {
            self.hangUpBtn.top = screenSize.height + 30;
        }
        [self.view layoutIfNeeded];
    }];
}






/*
- (void)renderVideoTrackInterface:(RTCVideoTrack *)videoTrack
{
    
}






//////////////////////////////////////////////////////////////////////////////////
#pragma mark RTCManagerDelegate
//////////////////////////////////////////////////////////////////////////////////


#pragma mark RTCManger开始RTC任务
- (void)rtcManagerDidStartRTCTask:(RTCManager *)sender
{
    NSLog(@"RTCVideoChatViewController 开始RTC任务...");
    
}



- (void)rtcManagerDidStopRTCTask:(RTCManager *)sender
{
    NSLog(@"RTCVideoChatViewController 停止RTC任务...");
    
}

- (void)rtcManager:(RTCManager *)sender didReceiveRemoteStream:(RTCMediaStream *)stream
{
    NSLog(@"RTCVideoChatViewController 接受到远程流...");
    NSAssert([stream.audioTracks count] >= 1, @"至少一个音频流");
    NSAssert([stream.videoTracks count] >= 1, @"至少一个视频流");
    
    if ([stream.videoTracks count] > 0) {
        [self renderVideoTrackInterface:[stream.videoTracks objectAtIndex:0]];
    }
}
*/



@end
