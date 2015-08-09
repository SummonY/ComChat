//
//  XMPPRoom+IM.h
//  ComChat
//
//  Created by D404 on 15/7/14.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPRoom.h"

@interface XMPPRoomManager : NSObject

+ (instancetype)sharedManager;


- (void)requestRegisterToRoom:(NSString *)roomJid;
- (void)commitRegisterFormToRoom:(NSString *)roomJid withNickname:(NSString *)nickname;

- (void)applyVoiceFromRoom:(NSString *)roomJid;     // 申请发言权

- (void)acceptInviteRoom:(XMPPJID *)jid;
- (void)rejectInviteRoom:(XMPPJID *)jid withReason:(NSString *)reason;


@end
