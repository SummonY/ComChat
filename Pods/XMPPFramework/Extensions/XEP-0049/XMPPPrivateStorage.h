//
//  XMPPPrivateStorage.h
//  XEP-0049
//
//  Created by D404 on 15/7/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#define _XMPP_PRIVATESTORAGE_H

#import <Foundation/Foundation.h>
#import "XMPPModule.h"
#import "XMPP.h"

@interface XMPPPrivateStorage : XMPPModule<XMPPStreamDelegate>

- (void)savePrivateStorageWithElement:(NSXMLElement *)element;
- (void)getPrivateStorateForElement:(NSXMLElement *)element;

@end

@protocol XMPPPrivateStorageDelegate

@optional
- (void)xmppPrivateStorage:(XMPPPrivateStorage *)sender didReceiveTimeoutForQueryID:(NSString *)queryID;
- (void)xmppPrivateStorage:(XMPPPrivateStorage *)sender didReceiveError:(XMPPIQ *)iq;
- (void)xmppPrivateStorage:(XMPPPrivateStorage *)sender didReceiveQueryElement:(NSXMLElement *)queryElement;
- (void)xmppPrivateStorage:(XMPPPrivateStorage *)sender didSaveXMPPIQ:(XMPPIQ *)xmppIQ;

@end
