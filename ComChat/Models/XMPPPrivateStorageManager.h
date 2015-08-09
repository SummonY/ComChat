//
//  XMPPPrivateStorage.h
//  ComChat
//  XEP-0049
//
//  Created by D404 on 15/7/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import "XMPPModule.h"
#import "XMPP.h"

@interface XMPPPrivateStorageManager : XMPPModule<XMPPStreamDelegate>

- (void)savePrivateStorageWithElement:(NSXMLElement *)element;
- (void)getPrivateStorateForElement:(NSXMLElement *)element;

@end


@protocol XMPPPrivateStorageManagerDelegate

@optional
- (void)xmppPrivateStorage:(XMPPPrivateStorageManager *)sender didReceiveTimeoutForQueryID:(NSString *)queryID;
- (void)xmppPrivateStorage:(XMPPPrivateStorageManager *)sender didReceiveError:(XMPPIQ *)iq;
- (void)xmppPrivateStorage:(XMPPPrivateStorageManager *)sender didReceiveQueryElement:(NSXMLElement *)queryElement;
- (void)xmppPrivateStorage:(XMPPPrivateStorageManager *)sender didSaveXMPPIQ:(XMPPIQ *)xmppIQ;

@end
