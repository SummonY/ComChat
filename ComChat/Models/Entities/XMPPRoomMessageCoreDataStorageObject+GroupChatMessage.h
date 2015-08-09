//
//  XMPPRoomMessageCoreDataStorageObject+GroupChatMessage.h
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <XMPPRoomMessageCoreDataStorageObject.h>
#import "ChatMessageEntityFactory.h"

@interface XMPPRoomMessageCoreDataStorageObject (GroupChatMessage)

@property (nonatomic, strong) ChatMessageBaseEntity *chatMessage;

- (NSString *)sectionIdentifier;

@end
