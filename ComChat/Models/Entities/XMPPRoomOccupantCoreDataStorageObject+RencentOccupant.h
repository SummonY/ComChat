//
//  XMPPRoomOccupantCoreDataStorageObject+RecentOccupant.h
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPRoomOccupantCoreDataStorageObject.h>

@interface XMPPRoomOccupantCoreDataStorageObject (RecentOccupant)

@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *chatRecord;
@property (nonatomic, strong) NSNumber *unreadMessages;     //
@property (nonatomic, assign) BOOL isChatting;              // 是否正在聊天


@end
