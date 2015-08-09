//
//  RTMonitoringViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RTMonitoringViewModel.h"
#import "XMPPManager.h"
#import "Macros.h"

@implementation RTMonitoringViewModel


#pragma mark 共享View Model
+ (instancetype)sharedViewModel
{
    static RTMonitoringViewModel *_shareedViewModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _shareedViewModel = [[self alloc] init];
    });
    return _shareedViewModel;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 开始搜索监测点
- (void)searchMonitor:(NSString *)monitor
{
    
}


- (void)sendMonitorInfo
{
    NSLog(@"发送监测点请求...");
    
    XMPPJID *serverJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@", XMPP_DOMAIN]];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:jianting"];
    
    NSXMLElement *sid = [NSXMLElement elementWithName:@"sid"];
    [sid addAttributeWithName:@"sid" stringValue:@"52"];
    
    [query addChild:sid];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}










///////////////////////////////////////////////////////////////////
#pragma mark DataSource
///////////////////////////////////////////////////////////////////



- (NSInteger)numberOfSections
{
    return 1;
}


- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

/*
- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    
}
*/




@end
