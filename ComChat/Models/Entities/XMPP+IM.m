//
//  XMPP+IM.m
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPP+IM.h"
#import <XMPP.h>

/////////////////////////////////////////////////////////////////////
#pragma mark 定义XMPPIQ的类别
/////////////////////////////////////////////////////////////////////

@implementation XMPPIQ (IM)


#pragma mark 判断是否为聊天室信息查询
- (BOOL)isChatRoomInfo
{
    if (self.children > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/disco#info"]) {
                BOOL has_identity = NO;
                BOOL has_feature = NO;
                for (NSXMLElement *item in element.children) {
                    if ([item.name isEqualToString:@"identity"]) {
                        has_identity = YES;
                    }
                    if ([item.name isEqualToString:@"feature"]) {
                        has_feature = YES;
                    }
                }
                return has_feature && has_identity;
            }
        }
    }
    return NO;
}


#pragma mark 判断是否是查询聊天室
- (BOOL)isChatRoomItems
{
    if (self.children > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/disco#items"]) {
                return YES;
            }
        }
    }
    return NO;
}



#pragma mark 判断是否是搜索联系人
- (BOOL)isSearchContacts
{
    if (self.children > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"jabber:iq:search"]) {
                for (NSXMLElement *x in element.children) {
                    if ([x.xmlns isEqualToString:@"jabber:x:data"]) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

#pragma mark 是否为群组获取好友列表
- (BOOL)isFetchMembersList
{
    if (self.children > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#admin"]) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark 判断是否为群组标签
- (BOOL)isRoomBookmarks
{
    if (self.children > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"jabber:iq:private"]) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark 判断是否为房间注册请求
- (BOOL)isRoomRegisterQuery:(NSString *)roomJid
{
    if (self.children > 0) {
        if ([self.attributesAsDictionary[@"id"] isEqualToString:[NSString stringWithFormat:@"RRTR%@", roomJid]]) {
            for (NSXMLElement *element in self.children) {
                if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"jabber:iq:register"]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}


#pragma mark 判断是否为房间注册提交结果
- (BOOL)isRoomRegisterCommitResult:(NSString *)roomJid
{
    if (self.children > 0) {
        if ([self.attributesAsDictionary[@"id"] isEqualToString:[NSString stringWithFormat:@"CRFTR%@", roomJid]]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark 判断是否为新闻消息
- (BOOL)isNewsMessage
{
    if (self.childCount > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"query"] && [element.xmlns isEqualToString:@"jabber:iq:news"]) {
                return YES;
            }
        }
    }
    return NO;
}



@end

/////////////////////////////////////////////////////////////////////
#pragma mark 定义XMPPPresence的类别
/////////////////////////////////////////////////////////////////////

@implementation XMPPPresence (IM)


#pragma mark 是否来自聊天室状态
- (BOOL)isChatRoomPresence
{
    if (self.childCount > 0){
        for (NSXMLElement* element in self.children) {
            if ([element.name isEqualToString:@"x"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]){
                for (NSXMLElement* element_a in element.children) {
                    if ([element_a.name isEqualToString:@"invite"]){
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}


#pragma mark 判断是否为申请加入房间
- (BOOL)isApplyToJoinRoom
{
    if (self.childCount > 0) {
        for (NSXMLElement *element in self.children) {
            if ([element.name isEqualToString:@"x"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]) {
                for (NSXMLElement *item in element.children) {
                    if ([item.attributesAsDictionary[@"affiliation"] isEqualToString:@"none"] && ![item.attributesAsDictionary[@"role"] isEqualToString:@"none"]) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}


@end


/////////////////////////////////////////////////////////////////////
#pragma mark 定义XMPPMesage的类别
/////////////////////////////////////////////////////////////////////

@implementation XMPPMessage (IM)


#pragma mark 是否来自房间邀请
- (BOOL)isChatRoomInvite
{
    if (self.childCount > 0){
        for (NSXMLElement* element in self.children) {
            if ([element.name isEqualToString:@"x"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]){
                for (NSXMLElement* element_a in element.children) {
                    if ([element_a.name isEqualToString:@"invite"]){
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

@end

