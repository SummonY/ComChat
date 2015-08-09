//
//  XMPPPrivateStorage.m
//  ComChat
//
//  Created by D404 on 15/7/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPPrivateStorageManager.h"
#import "XMPPManager.h"

#define PRIVATE_NAMESPACE       @"jabber:iq:private"

@interface XMPPPrivateStorageManager()

@property (nonatomic, strong) NSMutableSet *privateStorateIDs;

@end


@implementation XMPPPrivateStorageManager


- (NSString *)generatePrivateStorageID
{
    NSString *iqID = [self.xmppStream generateUUID];
    [self.privateStorateIDs addObject:iqID];
    [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(removeIqID:) userInfo:iqID repeats:NO];
    return iqID;
}

- (void)removeIqID:(NSTimer *)aTimer
{
    NSString *iqID = (NSString *)[aTimer userInfo];
    
    if([self.privateStorateIDs containsObject:iqID]) {
        [self.privateStorateIDs removeObject:iqID];
        [multicastDelegate xmppPrivateStorage:self didReceiveTimeoutForQueryID:iqID];
    }
}


- (void)savePrivateStorageWithElement:(NSXMLElement *)element
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:PRIVATE_NAMESPACE];
    [query addChild:element];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:[self generatePrivateStorageID] child:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}



- (void)getPrivateStorateForElement:(NSXMLElement *)element
{
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:PRIVATE_NAMESPACE];
    [query addChild:element];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:[self generatePrivateStorageID] child:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


@end
