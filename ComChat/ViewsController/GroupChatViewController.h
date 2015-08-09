//
//  GroupChatViewController.h
//  ComChat
//
//  Created by D404 on 15/7/10.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupChatViewModel.h"

@class XMPPJID;
@class XMPPRoomMessageCoreDataStorageObject;

@interface GroupChatViewController : UIViewController

@property (nonatomic, strong) GroupChatViewModel *groupChatViewModel;

+ (XMPPJID *)currentGroupJid;
+ (void)setCurrentGroupJid:(XMPPJID *)jid;

- (instancetype)initWithGroupJID:(XMPPJID *)groupJID groupName:(NSString *)groupName;

@end
