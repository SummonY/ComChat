//
//  XMPPRoomMessageCoreDataStorageObject+GroupChatMessage.m
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPRoomMessageCoreDataStorageObject+GroupChatMessage.h"
#import <objc/runtime.h>

static const char kChatMessageKey;
static const char kPrimitiveSectionIdentifier;

@interface XMPPRoomMessageCoreDataStorageObject ()

@property (nonatomic) NSString *primitiveSectionIdentifier;

@end


@implementation XMPPRoomMessageCoreDataStorageObject (GroupChatMessage)

#pragma mark 获取聊天消息实体
- (ChatMessageBaseEntity *)chatMessage
{
    ChatMessageBaseEntity *chatMessage = objc_getAssociatedObject(self, &kChatMessageKey);
    if (!chatMessage) {
        chatMessage = [ChatMessageEntityFactory messageFromJSONString:self.body];
        chatMessage.isOutgoing = self.isFromMe;
        if (chatMessage) {
            objc_setAssociatedObject(self, &kChatMessageKey, chatMessage, OBJC_ASSOCIATION_RETAIN);
        }
    }
    return chatMessage;
}

#pragma mark 设置聊天信息
- (void)setChatMessage:(ChatMessageBaseEntity *)chatMessage
{
    objc_setAssociatedObject(self, &kChatMessageKey, chatMessage, OBJC_ASSOCIATION_RETAIN);
}


#pragma mark 获取原始标识符
- (NSString *)primitiveSectionIdentifier
{
    return objc_getAssociatedObject(self, &kPrimitiveSectionIdentifier);
}

#pragma mark 设置原始标识符
- (void)setPrimitiveSectionIdentifier:(NSString *)primitiveSectionIdentifier
{
    objc_setAssociatedObject(self, &kPrimitiveSectionIdentifier, primitiveSectionIdentifier, OBJC_ASSOCIATION_RETAIN);
}


#pragma mark 初始化查找关键字，用户获取消息时查找
- (NSString *)sectionIdentifier
{
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *tmp = [self primitiveSectionIdentifier];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!tmp) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        tmp = [formatter stringFromDate:self.localTimestamp];
        
        [self setPrimitiveSectionIdentifier:tmp];
    }
    return tmp;
}

#pragma mark key path dependencies
+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier
{
    return [NSSet setWithObject:@"timestamp"];
}


/**
 * Optional override hook for general extensions.
 *
 * @see insertMessage:outgoing:forRoom:stream:
 **/
- (void)didInsertMessage:(XMPPRoomMessageCoreDataStorageObject *)message
{
    // Override me if you're extending the XMPPRoomMessageCoreDataStorageObject class to add additional properties.
    // You can update your additional properties here.
    //
    // At this point the standard properties have already been set.
    // So you can, for example, access the XMPPMessage via message.message.
    NSLog(@"XMPPRoomMessageCoreDataStorageObject已经插入消息");
    
}



@end
