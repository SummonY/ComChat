//
//  XMPPMessage+Signaling.m
//  ComChat
//
//  Created by D404 on 15/6/25.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPMessage+Signaling.h"

#define TYPE_SIGNALING          @"signaling"

#pragma mark 扩展信号消息
@implementation XMPPMessage(Signaling)

+ (XMPPMessage *)signalineMessageTo:(XMPPJID *)jid elementID:(NSString *)elementId child:(NSXMLElement *)childElement
{
    return [[XMPPMessage alloc] initSignalingMessageTo:jid elementID:elementId child:childElement];
}

#pragma 初始化信号消息
- (id)initSignalingMessageTo:(XMPPJID *)jid elementID:(NSString *)elementId child:(NSXMLElement *)childElement
{
    return [[XMPPMessage alloc] initWithType:TYPE_SIGNALING to:jid elementID:elementId child:childElement];
}

#pragma mark 判断是否为信号消息
- (BOOL)isSignalingMessage
{
    return [[[self attributeForName:@"type"] stringValue] isEqualToString:TYPE_SIGNALING];
}

#pragma mark 如果是新好消息则返回消息体
- (BOOL)isSignalingMessageWithBody
{
    if ([self isSignalingMessage]) {
        return [self isMessageWithBody];
    }
    return NO;
}


@end
