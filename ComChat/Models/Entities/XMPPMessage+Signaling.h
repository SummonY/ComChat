//
//  XMPPMessage+Signaling.h
//  ComChat
//
//  Created by D404 on 15/6/25.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPMessage.h>

@interface XMPPMessage(Signaling)

+ (XMPPMessage *)signalineMessageTo:(XMPPJID *)jid elementID:(NSString *)elementId child:(NSXMLElement *)childElement;
- (id)initSignalingMessageTo:(XMPPJID *)jid elementID:(NSString *)elementId child:(NSXMLElement *)childElement;

- (BOOL)isSignalingMessage;
- (BOOL)isSignalingMessageWithBody;

@end
