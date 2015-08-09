//
//  XMPPMessageArchiving_Message_CoreDataObject+ChatMessage.h
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <XMPPMessageArchiving_Message_CoreDataObject.h>
#import "ChatMessageEntityFactory.h"

@interface XMPPMessageArchiving_Message_CoreDataObject (ChatMessage)

@property (nonatomic, strong) ChatMessageBaseEntity *chatMessage;

- (NSString *)sectionIdentifier;

@end
