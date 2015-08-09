//
//  RTCManager.m
//  ComChat
//
//  Created by D404 on 15/6/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RTCManager.h"
#import "XMPPManager.h"
/*
#import <RTCPeerConnection.h>
#import <RTCPeerConnectionFactory.h>
#import <RTCMediaConstraints.h>
#import <RTCMediaStream.h>
#import <RTCPair.h>
#import <RTCICEServer.h>
#import <RTCVideoCapturer.h>
#import <RTCVideoSource.h>
#import <RTCVideoTrack.h>
#import <RTCSessionDescription.h>
#import <RTCICECandidate.h>

#import <AVFoundation/AVFoundation.h>

@interface RTCManager()

@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;
@property (nonatomic, strong) NSMutableArray *queuedSignalingMessage;
@property (nonatomic, strong) RTCMediaConstraints *pcConstraints;
@property (nonatomic, strong) RTCMediaConstraints *sdpConstraints;
@property (nonatomic, strong) RTCMediaConstraints *videoConstraints;
@property (nonatomic, strong) RTCPeerConnection *peerConnection;
@property (nonatomic, strong) RTCVideoCapturer *localVideoCapture;
@property (nonatomic, strong) RTCVideoSource *localVideoSource;
@property (nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) RTCAudioTrack *localAudioTrack;

@property (nonatomic, assign) BOOL hasCreatedPeerConnection;


@end


@implementation RTCManager


#pragma mark 生成单例类对象
+ (instancetype)sharedManager
{
    static RTCManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

#pragma mark 初始化
- (id)init
{
    if (self = [super init]) {
        self.rtcTarget = Nil;
    }
    return self;
}


#pragma mark 开启引擎
- (void)startEngine
{
    NSLog(@"开启引擎...");
    
    [XMPPManager sharedManager].signalingDelegate = self;
    
    [RTCPeerConnectionFactory initializeSSL];
    self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    self.queuedSignalingMessage = [NSMutableArray array];
    
    // 设置RTCPeerConnection's constraints
    self.pcConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"], [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]] optionalConstraints:@[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"false"]]];
    
    // 设置SDP‘s(offer/answer) Constraints
    self.sdpConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"], [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]] optionalConstraints:nil];
    
    // 设置RTCVideoSource's(localVideoSource) Constraints
    RTCPair *maxAspectRatio = [[RTCPair alloc] initWithKey:@"maxAspectRatio" value:@"4:3"];
    
    // 设置宽度和高度
    RTCPair *maxWidth = [[RTCPair alloc] initWithKey:@"maxWidth" value:@"320"];
    RTCPair *minWidth = [[RTCPair alloc] initWithKey:@"minWidth" value:@"160"];
    
    RTCPair *maxHeight = [[RTCPair alloc] initWithKey:@"maxHeight" value:@"240"];
    RTCPair *minHeight = [[RTCPair alloc] initWithKey:@"minHeight" value:@"120"];
    
    // 设置帧率
    RTCPair *maxFrameRate = [[RTCPair alloc] initWithKey:@"maxFrameRate" value:@"30"];
    RTCPair *minFrameRate = [[RTCPair alloc] initWithKey:@"minFrameRate" value:@"24"];
    
    NSArray *mandatory = @[maxAspectRatio, maxWidth, minWidth, maxHeight, minHeight, maxFrameRate, minFrameRate];
    self.videoConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
    
}


#pragma mark 关闭引擎
- (void)stopEngine
{
    NSLog(@"关闭引擎...");
    
    [XMPPManager sharedManager].signalingDelegate = nil;
    [RTCPeerConnectionFactory deinitializeSSL];
    
    [self.queuedSignalingMessage removeAllObjects];
    self.queuedSignalingMessage = nil;
    
    self.pcConstraints = nil;
    self.sdpConstraints = nil;
    self.videoConstraints = nil;
    self.peerConnectionFactory = nil;
}


#pragma mark 开始RTC任务
- (BOOL)startRTCTaskAsInitiator:(BOOL)flag withTarget:(NSString *)targetJID
{
    NSLog(@"开始RTC任务初始化...");
    
    self.isInitiator = flag;
    self.rtcTarget = targetJID;
    
    NSArray *servers = [self getLastICEServers];
    
    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:servers constraints:self.pcConstraints delegate:self];
    self.hasCreatedPeerConnection = YES;
    
    NSLog(@"添加音频和视频设备...");
    
    // 设置本地媒体流
    RTCMediaStream *mediaStream = [self.peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    
    // 添加本地视频轨迹
    if (!self.localVideoCapture) {
        NSString *cameraID = nil;
        for (AVCaptureDevice *captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (!cameraID || captureDevice.position == AVCaptureDevicePositionFront) {
                cameraID = [captureDevice localizedName];
            }
        }
        self.localVideoCapture = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    }
    if (!self.localVideoSource) {
        self.localVideoSource = [self.peerConnectionFactory videoSourceWithCapturer:self.localVideoCapture constraints:self.videoConstraints];
    }
    if (!self.localVideoTrack) {
        self.localVideoTrack = [self.peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:self.localVideoSource];
    }
    if (self.localVideoTrack) {
        [mediaStream addVideoTrack:self.localVideoTrack];
    }
    
    // 添加本地音频轨迹
    if (!self.localAudioTrack) {
        self.localAudioTrack = [self.peerConnectionFactory audioTrackWithID:@"ARDAMSa0"];
    }
    if (self.localAudioTrack) {
        [mediaStream addAudioTrack:self.localAudioTrack];
    }
    
    // 添加本地流
    [self.peerConnection addStream:mediaStream];
    
    if (self.isInitiator) {
        [self callerStart];
    } else {
        [self calleeStart];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcManagerDidStartRTCTask:)]) {
        [self.delegate rtcManagerDidStartRTCTask:self];
    }
    
    return YES;
}


#pragma mark 停止RTC任务
- (void)stopRTCTaskAsInitiator:(BOOL)flag
{
    NSLog(@"停止RTC任务...");
    
    if (self.peerConnection) {
        [self.queuedSignalingMessage removeAllObjects];
        
        [self.peerConnection close];
        self.peerConnection = nil;
        self.hasCreatedPeerConnection = NO;
        self.isInitiator = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(rtcManagerDidStopRTCTask:)]) {
            [self.delegate rtcManagerDidStopRTCTask:self];
        }
        
        if (flag) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSDictionary *jsonDict = @{@"type" : @"bye"};
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
                NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error : %@", [error description]]);
                NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                NSAssert(self.rtcTarget != Nil, @"rtcTarget can't be nil");
                [[XMPPManager sharedManager] sendSignalingMessage:jsonStr toJID:self.rtcTarget];
            });
        }
    }
}



#pragma mark 设置STUN/TURN服务器，若没有该服务器，则只能在局域网中使用
- (NSArray *)getLastICEServers
{
    NSLog(@"设置ICE服务器...");
    
    NSMutableArray *ICEServers = [NSMutableArray array];
    
 
    //RTCICEServer *ICEServer = [[RTCICEServer alloc] initWithURI:<#(NSURL *)#> username:<#(NSString *)#> password:<#(NSString *)#>];
    //[ICEServers addObject:ICEServer];
 
    
    return ICEServers;
}

#pragma mark 创建Offer
- (void)callerStart
{
    NSLog(@"创建Offer...");
    [self.peerConnection createOfferWithDelegate:self constraints:self.sdpConstraints];
}


- (void)calleeStart
{
    for (int i = 0; i < [self.queuedSignalingMessage count]; ++i) {
        NSString *message = [self.queuedSignalingMessage objectAtIndex:i];
        [self processSignalingMessage:message];
    }
}


#pragma mark 处理信号消息
- (void)processSignalingMessage:(NSString *)message
{
    if (!self.hasCreatedPeerConnection) {
        NSLog(@"还没有创建 peerConnection...");
        return ;
    }
    
    NSString *jsonStr = message;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    NSAssert(!error, @"%@", [NSString stringWithFormat:@"错误: %@", [error description]]);
    NSString *type = [jsonDict objectForKey:@"type"];
    if ([type compare:@"offer"] == NSOrderedSame) {
        NSString *sdpString = [jsonDict objectForKey:@"sdp"];
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:[RTCManager preferISAC:sdpString]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
        
        // 创建answer
        NSLog(@"创建Answer...");
        [self.peerConnection createAnswerWithDelegate:self constraints:self.sdpConstraints];
    } else if ([type compare:@"answer"] == NSOrderedSame) {
        NSString *sdpString = [jsonDict objectForKey:@"sdp"];
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:[RTCManager preferISAC:sdpString]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
    } else if ([type compare:@"candidate"] == NSOrderedSame) {
        NSString *mid = [jsonDict objectForKey:@"id"];
        NSNumber *sdpLineIndex = [jsonDict objectForKey:@"label"];
        NSString *sdp = [jsonDict objectForKey:@"candidate"];
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid index:sdpLineIndex.intValue sdp:sdp];
        [self.peerConnection addICECandidate:candidate];
    } else if ([type compare:@"bye"] == NSOrderedSame) {
        [self stopRTCTaskAsInitiator:NO];
    }
}



#pragma mark Utility Methods for RTCSessionDescription
// Match |pattern| to |string| 并返回第一组匹配，若没有匹配返回nil
+ (NSString *)firstMatch:(NSRegularExpression *)pattern withString:(NSString *)string
{
    NSTextCheckingResult *result = [pattern firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (!result) {
        return nil;
    }
    return [string substringWithRange:[result rangeAtIndex:1]];
}





#pragma mark 管理origSDP来ISAC/16k音频码
+ (NSString *)preferISAC:(NSString *)origSDP
{
    int mLineIndex = -1;
    NSString *isac16kRtpMap = nil;
    NSArray *lines = [origSDP componentsSeparatedByString:@"\n"];
    NSRegularExpression *isac16kRegex = [NSRegularExpression regularExpressionWithPattern:@"^a=rtpmap:(\\d+) ISAC/16000[\r]?$" options:0 error:nil];
    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) {
        NSString *line = [lines objectAtIndex:i];
        if ([line hasPrefix:@"m=audio "]) {
            mLineIndex = i;
            continue;
        }
        isac16kRtpMap = [self firstMatch:isac16kRegex withString:line];
    }
    if (mLineIndex == -1) {
        NSLog(@"没有 m = audio 行，无法选择iSAC");
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        NSLog(@"没有iSAC/16000行，无法选择iSAC");
        return origSDP;
    }
    
    NSArray *origMLineParts = [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray *newMLine = [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // 格式化形式:m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]] != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex withObject:[newMLine componentsJoinedByString:@" "]];
    
    return [newLines componentsJoinedByString:@"\n"];
}







////////////////////////////////////////////////////////////////////////////////////
#pragma mark peerConnectionDelegate
////////////////////////////////////////////////////////////////////////////////////




- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream
{
    NSLog(@"对等连接添加媒体流...");
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(rtcManager:didReceiveRemoteStream:)]) {
            [self.delegate rtcManager:self didReceiveRemoteStream:stream];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream
{
    NSLog(@"对等连接删除媒体流...");
    [stream removeVideoTrack:[stream.videoTracks objectAtIndex:0]];
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
    NSLog(@"对等连接需要重新协商...");
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged
{
    NSLog(@"对等连接信号状态变化..., state = %u", stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState
{
    NSLog(@"对等连接ICE连接变化..., state = %u", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState
{
    NSLog(@"对等连接ICE采集变化, state = %u", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate
{
    NSLog(@"获取到ICE候选, %@", candidate);
    
    NSDictionary *jsonDict = @{@"type" : @"candidate", @"label" : [NSNumber numberWithInt:candidate.sdpMLineIndex], @"id" : candidate.sdpMid, @"candidate" : candidate.sdp};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    if (!error) {
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"candidate : %@", jsonStr);
        
        NSAssert(self.rtcTarget != Nil, @"rtcTarget 不能为空");
        [[XMPPManager sharedManager] sendSignalingMessage:jsonStr toJID:self.rtcTarget];
    } else {
        NSAssert(NO, @"序列化JSON对象错误: %@", error.localizedDescription);
    }
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark RTCSession Description Delegate
////////////////////////////////////////////////////////////////////////////////////


- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)origSdp error:(NSError *)error
{
    NSLog(@"已创建会话描述符");
    
    if (error) {
        NSAssert(NO, @"%@", [NSString stringWithFormat:@"Error : %@", [error description]]);
        return ;
    }
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:origSdp.type sdp:[RTCManager preferISAC:origSdp.description]];
    [self.peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSDictionary *jsonDict = @{@"type" : sdp.type, @"sdp" : sdp.description};
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
        NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error: %@", error.description]);
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"SDP JSON字符串: %@", jsonStr);
        
        NSAssert(self.rtcTarget != Nil, @"RTCTarget 不能为空");
        [[XMPPManager sharedManager] sendSignalingMessage:jsonStr toJID:self.rtcTarget];
    });
}


#pragma mark 设置远程或本地描述符
- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error
{
    NSLog(@"设置会话描述符...");
    
    if (error) {
        NSAssert(NO, @"%@", [NSString stringWithFormat:@"Error: %@", [error description]]);
        return ;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (self.peerConnection.remoteDescription) {
            NSLog(@"SDP成功 - drain candidates");
        } else {
            NSLog(@"SDP远程描述符为空");
        }
    });
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPManager Signaling Delegate
////////////////////////////////////////////////////////////////////////////////////

#pragma mark 接收到信号
- (void)xmppManager:(XMPPManager *)sender didReceiveSignalingMessage:(XMPPMessage *)message
{
    NSLog(@"接收到信号消息: %@", message);
    
    if ([message isMessageWithBody]) {
        NSString *jidFrom = [[message from] bare];
        NSString *jsonStr = [message body];
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error : %@", error.description]);
        NSString *type = [jsonDict objectForKey:@"type"];
        
        if (!self.isInitiator && !self.hasCreatedPeerConnection) {
            if ([type compare:@"offer"] == NSOrderedSame) {
                [self.queuedSignalingMessage insertObject:jsonStr atIndex:0];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(rtcManagerDidReceiveRTCTaskRequest:fromUser:)]) {
                    [self.delegate rtcManagerDidReceiveRTCTaskRequest:self fromUser:jidFrom];
                }
            } else {
                [self.queuedSignalingMessage addObject:jsonStr];
            }
        } else {
            [self processSignalingMessage:jsonStr];
        }
    }
}

@end
*/
