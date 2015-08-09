//
//  XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPMessageArchiving_Contact_CoreDataObject.h"

@interface XMPPMessageArchiving_Contact_CoreDataObject (RecentContact)      // 从联系人中获取正在聊天的联系人

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *chatRecord;
@property (nonatomic, strong) NSNumber *unreadMessages;     // 
@property (nonatomic, assign) BOOL isChatting;              // 是否正在聊天


@end
