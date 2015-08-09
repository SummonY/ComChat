//
//  XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.h"
#import <objc/runtime.h>
#import "XMPPManager.h"
#import "ChatViewController.h"


static const char kDisplayNameKey;
static const char kChatRecordKey;
static const char kUnreadMessagesKey;

@implementation XMPPMessageArchiving_Contact_CoreDataObject (RecentContact)

#pragma mark 获取显示名称
- (NSString *)displayName
{
    return objc_getAssociatedObject(self, &kDisplayNameKey);
}

#pragma mark 设置显示名称
- (void)setDisplayName:(NSString *)displayName
{
    objc_setAssociatedObject(self, &kDisplayNameKey, displayName, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark 获取聊天记录
- (NSString *)chatRecord
{
    return objc_getAssociatedObject(self, &kChatRecordKey);
}

#pragma mark 设置聊天记录
- (void)setChatRecord:(NSString *)chatRecord
{
    objc_setAssociatedObject(self, &kChatRecordKey, chatRecord, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark 获取未读消息数
- (NSNumber *)unreadMessages
{
    NSNumber *unreadNum = objc_getAssociatedObject(self, &kUnreadMessagesKey);
    if (!unreadNum) {
        NSString *contactUnreadMessageKey = [NSString stringWithFormat:@"%@%@", self.bareJidStr, self.streamBareJidStr];
        unreadNum = [[NSUserDefaults standardUserDefaults] objectForKey:contactUnreadMessageKey];
    }
    return unreadNum;
}

#pragma mark 设置未读消息数
- (void)setUnreadMessages:(NSNumber *)unreadMessages
{
    objc_setAssociatedObject(self, &kUnreadMessagesKey, unreadMessages, OBJC_ASSOCIATION_RETAIN);
}


#pragma mark Hooks重载当前插入联系人
- (void)willInsertObject
{
    // If you extend XMPPMessageArchiving_Contact_CoreDataObject,
    // you can override this method to use as a hook to set your own custom properties.
    
    NSLog(@"添加XMPPMessageArchiving_Contact_CoreDataObject");
    
    if (![self.mostRecentMessageOutgoing boolValue]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            XMPPUserCoreDataStorageObject *rosterUser =
            [[XMPPManager sharedManager].xmppRosterStorage userForJID:self.bareJid
                                                           xmppStream:[XMPPManager sharedManager].xmppStream
                                                 managedObjectContext:[XMPPManager sharedManager].managedObjectContext_roster];
            
            // 不是当前聊天，则需要修改未读消息数
            if (![[ChatViewController currentBuddyJid] isEqualToJID:rosterUser.jid options:XMPPJIDCompareBare]) {
                
                rosterUser.unreadMessages = @1;
                
                NSError *error = nil;
                if (![[XMPPManager sharedManager].managedObjectContext_roster save:&error]) {
                    NSLog(@"willInsertObject 保存出错: %@", [error description]);
                }
            }
        });
    }
}

#pragma mark 重载更新当前联系人
- (void)didUpdateObject
{
    // If you extend XMPPMessageArchiving_Contact_CoreDataObject,
    // you can override this method to use as a hook to update your own custom properties.
    
    NSLog(@"更新XMPPMessageArchiving_Contact_CoreDataObject");
    
    // 有新的消息来，user表中+1，保存
    if (![self.mostRecentMessageOutgoing boolValue]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            XMPPUserCoreDataStorageObject *rosterUser =
            [[XMPPManager sharedManager].xmppRosterStorage userForJID:self.bareJid
                                                           xmppStream:[XMPPManager sharedManager].xmppStream
                                                 managedObjectContext:[XMPPManager sharedManager].managedObjectContext_roster];
            
            // 不是当前聊天，则需要修改未读消息数
            if (![[ChatViewController currentBuddyJid] isEqualToJID:rosterUser.jid options:XMPPJIDCompareBare]) {
                
                rosterUser.unreadMessages = [NSNumber numberWithInt:rosterUser.unreadMessages.intValue + 1];
                NSError *error = nil;
                if (![[XMPPManager sharedManager].managedObjectContext_roster save:&error]) {
                    NSLog(@"didUpdateObject save error: %@", [error description]);
                }
            }
        });
    }
}

@end
