//
//  XMPPBookmarkManager.h
//  ComChat
//  XEP-0048
//
//  Created by D404 on 15/7/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPBookmarkManager : NSObject

@property (nonatomic, strong) NSMutableArray *bookmarkedRooms;
@property (nonatomic, strong) NSMutableArray *bookmarks;


+ (instancetype)sharedManager;

- (void)getBookmarkRooms;
- (void)addBookmarkToRoomName:(NSString *)roomName isAutoJoin:(BOOL)autoJoin roomJid:(NSString *)roomJID nickname:(NSString *)nickName;
- (void)removeBookmarkRoomJid:(NSString *)roomJid;

@end
