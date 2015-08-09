//
//  XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.m
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.h"
#import <objc/runtime.h>
#import "GroupChatViewController.h"

static const char kDisplayNameKey;
static const char kChatRecordKey;
static const char kUnreadMessagesKey;

@implementation XMPPRoomOccupantCoreDataStorageObject (RecentOccupant)

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
        NSString *roomUnreadMessageKey = [NSString stringWithFormat:@"%@%@", self.jidStr, self.streamBareJidStr];
        unreadNum = [[NSUserDefaults standardUserDefaults] objectForKey:roomUnreadMessageKey];
    }
    return unreadNum;
}

#pragma mark 设置未读消息数
- (void)setUnreadMessages:(NSNumber *)unreadMessages
{
    objc_setAssociatedObject(self, &kUnreadMessagesKey, unreadMessages, OBJC_ASSOCIATION_RETAIN);
}





#pragma mark Hooks
- (void)didInsertOccupant:(XMPPRoomOccupantCoreDataStorageObject *)occupant
{
    // Override me if you're extending the XMPPRoomOccupantCoreDataStorageObject class to add additional properties.
    // You can update your additional properties here.
    NSLog(@"添加XMPPRoomOccupantCoreDataStorageObject");
    
    
}

/**
 * Optional override hook for general extensions.
 *
 * @see updateOccupant:withPresence:room:stream:
 **/
- (void)didUpdateOccupant:(XMPPRoomOccupantCoreDataStorageObject *)occupant
{
    // Override me if you're extending the XMPPRoomOccupantCoreDataStorageObject class to add additional properties.
    // You can update your additional properties here.
    NSLog(@"更新XMPPRoomOccupantCoreDataStorageObject");
    

}



@end