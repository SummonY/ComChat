//
//  ChatViewController.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatViewModel.h"

@class XMPPJID;
@class XMPPMessageArchiving_Contact_CoreDataObject;

@interface ChatViewController : UIViewController

@property (nonatomic, strong) ChatViewModel *chatViewModel;

+ (XMPPJID *) currentBuddyJid;
+ (void)setCurrentBuddyJid:(XMPPJID *)jid;

- (instancetype)initWithBuddyJID:(XMPPJID *)buddyJID buddyName:(NSString *)buddyName;


@end
