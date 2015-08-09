//
//  XMPP+IM.h
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <XMPPIQ.h>
#import <XMPPMessage.h>
#import <XMPPPresence.h>

@interface XMPPIQ (IM)

- (BOOL)isChatRoomItems;                                    // 是否为聊天室请求列表
- (BOOL)isChatRoomInfo;                                     // 是否是聊天室查询信息
- (BOOL)isSearchContacts;                                   // 是否是搜索联系人
- (BOOL)isFetchMembersList;                                 // 是否为群组获取好友列表
- (BOOL)isRoomBookmarks;                                    // 是否为群组标签
- (BOOL)isRoomRegisterQuery:(NSString *)roomJid;            // 是否为群组注册请求
- (BOOL)isRoomRegisterCommitResult:(NSString *)roomJid;     // 是否位群组注册提交结果
- (BOOL)isNewsMessage;                                      // 是否为新闻消息

@end


@interface XMPPMessage (IM)

- (BOOL)isChatRoomInvite;       // 是否来自聊天室邀请

@end


@interface XMPPPresence (IM)

- (BOOL)isChatRoomPresence;     // 是否来自聊天室状态
- (BOOL)isApplyToJoinRoom;      // 是否是申请加入房间

@end