//
//  XMPPMessageArchiving_Message_CoreDataObject+ChatMessage.m
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPMessageArchiving_Message_CoreDataObject+ChatMessage.h"
#import <objc/runtime.h>

static const char kChatMessageKey;
static const char kPrimitiveSectionIdentifier;

@interface XMPPMessageArchiving_Message_CoreDataObject ()

@property (nonatomic) NSString *primitiveSectionIdentifier;

@end


@implementation XMPPMessageArchiving_Message_CoreDataObject (ChatMessage)

#pragma mark 获取聊天消息实体
- (ChatMessageBaseEntity *)chatMessage
{
    ChatMessageBaseEntity *chatMessage = objc_getAssociatedObject(self, &kChatMessageKey);
    if (!chatMessage) {
        chatMessage = [ChatMessageEntityFactory messageFromJSONString:self.body];
        chatMessage.isOutgoing = self.isOutgoing;
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
        tmp = [formatter stringFromDate:self.timestamp];
        
        [self setPrimitiveSectionIdentifier:tmp];
    }
    return tmp;
}

#pragma mark key path dependencies
+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier
{
    return [NSSet setWithObject:@"timestamp"];
}

@end
