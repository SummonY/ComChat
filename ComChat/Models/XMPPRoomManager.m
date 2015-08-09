//
//  XMPPRoom+IM.m
//  ComChat
//
//  Created by D404 on 15/7/14.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPRoomManager.h"
#import <XMPPLogging.h>
#import "XMPPManager.h"


// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif


@implementation XMPPRoomManager


#pragma mark 共享管理类
+ (instancetype)sharedManager
{
    static XMPPRoomManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}




#pragma mark 请求注册到房间
- (void)requestRegisterToRoom:(NSString *)roomJid
{
    // <iq type="get" from="myFullJID" to="roomJid" id="reg1">
    //   <query xmlns="jabber:iq:register"/>
    // </iq>
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [iq addAttributeWithName:@"to" stringValue:roomJid];
    [iq addAttributeWithName:@"id" stringValue:[NSString stringWithFormat:@"RRTR%@", roomJid]];
    [iq addChild:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 提交注册表单
- (void)commitRegisterFormToRoom:(NSString *)roomJid withNickname:(NSString *)nickname
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *field;
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#register"]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_first"];                      // 注册房间first name
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_last"];                       // 注册房间last name
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_roomnick"];                   // 注册房间昵称
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_url"];                        // 注册房间URL
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:[NSString stringWithFormat:@"http://%@/", nickname]]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_email"];                      // 注册房间邮箱
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#register_faqentry"];                   // 注册房间常用问题
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:nickname]];
    [x addChild:field];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    [query addChild:x];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [iq addAttributeWithName:@"to" stringValue:roomJid];
    [iq addAttributeWithName:@"id" stringValue:[NSString stringWithFormat:@"CRFTR%@", roomJid]];
    [iq addChild:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 向房间申请发言权
- (void)applyVoiceFromRoom:(NSString *)roomJid
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *field;
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#request"]];
    [x addChild:field];
    
    field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#role"];
    [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"participant"]];
    [x addChild:field];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:roomJid];
    [message addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [message addChild:x];
    
    [[XMPPManager sharedManager].xmppStream sendElement:message];
}


#pragma mark 接受房间邀请
- (void)acceptInviteRoom:(XMPPJID *)jid
{
    XMPPLogTrace();
    
    NSXMLElement *invite = [NSXMLElement elementWithName:@"invite"];
    [invite addAttributeWithName:@"to" stringValue:[jid full]];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCUserNamespace];
    [x addChild:invite];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:[jid full]];
    [message addChild:x];
    
    [[XMPPManager sharedManager].xmppStream sendElement:message];
}


#pragma mark 拒绝房间邀请
- (void)rejectInviteRoom:(XMPPJID *)jid withReason:(NSString *)reasonStr
{
    // <message to='darkcave@chat.shakespeare.lit'>
    //   <x xmlns='http://jabber.org/protocol/muc#user'>
    //     <decline to='hecate@shakespeare.lit'>
    //       <reason>
    //         Sorry, I'm too busy right now.
    //       </reason>
    //     </decline>
    //   </x>
    // </message>
    
    NSXMLElement *reason = [NSXMLElement elementWithName:@"reason"];
    [reason setStringValue:reasonStr];
    
    NSXMLElement *decline = [NSXMLElement elementWithName:@"decline"];
    [decline addAttributeWithName:@"to" stringValue:[jid full]];
    [decline addChild:reason];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:XMPPMUCUserNamespace];
    [x addChild:decline];
    
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"to" stringValue:[jid full]];
    [message addChild:x];
    
    [[XMPPManager sharedManager].xmppStream sendElement:message];
}



@end
