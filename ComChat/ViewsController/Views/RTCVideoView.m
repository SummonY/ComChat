//
//  RTCVideoView.m
//  ComChat
//
//  Created by D404 on 15/6/26.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RTCVideoView.h"
/*
#import <RTCVideoTrack.h>
#import <RTCVideoRenderer.h>


@interface RTCVideoView()

@property (nonatomic, strong) UIView<RTCVideoRenderView> *videoRenderView;
@property (nonatomic, strong) RTCVideoRenderer *videoRenderer;
@property (nonatomic, strong) RTCVideoTrack *videoTrack;

@end


@implementation RTCVideoView

#pragma mark 初始化框架
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor lightGrayColor]];
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        
        CGRect renderViewFrame = CGRectMake(0, 0, screenSize.width, screenSize.height - 50);
        self.videoRenderView = [RTCVideoRenderer newRenderViewWithFrame:renderViewFrame];
        self.videoRenderer = [[RTCVideoRenderer alloc] initWithRenderView:[self videoRenderView]];
        [self addSubview:self.videoRenderView];
    }
    return self;
}

#pragma mark 暂停
- (void)pause:(id)sender
{
    [self.videoRenderer stop];
}

#pragma mark 开始
- (void)resume:(id)sender
{
    [self.videoRenderer start];
}

#pragma mark 停止
- (void)stop:(id)sender
{
    [self.videoRenderer stop];
    [self.videoTrack removeRenderer:self.videoRenderer];
    self.videoTrack = nil;
}

#pragma mark 停止Render
- (void)stopRender
{
    [self stop:nil];
}

- (void)renderVideoTrackInterface:(RTCVideoTrack *)videoTrack
{
    if (self.videoTrack) {
        [self stop:nil];
    }
    self.videoTrack = videoTrack;
    if (self.videoTrack && self.videoRenderer) {
        [self.videoTrack addRenderer:self.videoRenderer];
        [self resume:self];
        NSLog(@"开始视频...");
    }
}






@end
*/