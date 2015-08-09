//
//  RTCManager.h
//  ComChat
//
//  Created by D404 on 15/6/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPManager.h"
/*
#import <RTCPeerConnectionDelegate.h>
#import <RTCSessionDescriptionDelegate.h>


@protocol RTCManagerDelegate;

@interface RTCManager : NSObject<RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, XMPPManagerSignalingDelegate>

@property (nonatomic, copy) NSString *rtcTarget;
@property (nonatomic, assign) BOOL isInitiator;

@property (nonatomic, weak) id<RTCManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)startEngine;
- (void)stopEngine;
- (BOOL)startRTCTaskAsInitiator:(BOOL)flag withTarget:(NSString *)targetJID;
- (void)stopRTCTaskAsInitiator:(BOOL)flag;

@end


@protocol RTCManagerDelegate <NSObject>

@optional
- (void)rtcManagerDidStartRTCTask:(RTCManager *)sender;
- (void)rtcManagerDidStopRTCTask:(RTCManager *)sender;
- (void)rtcManager:(RTCManager *)sender didReceiveRemoteStream:(RTCMediaStream *)stream;
- (void)rtcManagerDidReceiveRTCTaskRequest:(RTCManager *)sender fromUser:(NSString *)bareJID;

@end
*/