//
//  XMPPBookmarkManager.m
//  ComChat
//
//  Created by D404 on 15/7/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPBookmarkManager.h"
#import "XMPPPrivateStorageManager.h"
#import <XMPP.h>

@interface XMPPBookmarkManager ()

@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *roomJID;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *removeRoomJid;

@property (nonatomic, strong) XMPPPrivateStorageManager *privateStorage;


@end


@implementation XMPPBookmarkManager


#pragma mark 共享管理类
+ (instancetype)sharedManager
{
    static XMPPBookmarkManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
        [_sharedManager initStorage];
    });
    return _sharedManager;
}

- (void)initStorage
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addBookmarkNotify)
                                                 name:@"ADD_BOOK_MARK_NOTIFY"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeBookmarkNotify)
                                                 name:@"REMOVE_BOOK_MARK_NOTIFY"
                                               object:nil];
    self.privateStorage = [[XMPPPrivateStorageManager alloc] init];
}


- (void)addBookmarkNotify
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference;
    for (int i = 0; i < self.bookmarkedRooms.count; ++i) {
        conference = [NSXMLElement elementWithName:@"conference"];
        [conference addAttributeWithName:@"name" stringValue:@"BookmarkedRoom"];
        [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
        [conference addAttributeWithName:@"jid" stringValue:self.bookmarkedRooms[i]];
        [conference addAttributeWithName:@"nick" stringValue:self.nickName];
        
        [storage addChild:conference];
    }
    
    conference = [NSXMLElement elementWithName:@"conference"];
    [conference addAttributeWithName:@"name" stringValue:@"BookmarkedRoom"];
    [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
    [conference addAttributeWithName:@"jid" stringValue:self.roomJID];
    [conference addAttributeWithName:@"nick" stringValue:self.nickName];
    
    [storage addChild:conference];
    
    [self.privateStorage savePrivateStorageWithElement:storage];
}

#pragma mark 删除房间标签
- (void)removeBookmarkNotify
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference;
    for (int i = 0; i < self.bookmarkedRooms.count; ++i) {
        if (![self.removeRoomJid isEqualToString:self.bookmarkedRooms[i]]) {
            conference = [NSXMLElement elementWithName:@"conference"];
            [conference addAttributeWithName:@"name" stringValue:@"BookmarkedRoom"];
            [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
            [conference addAttributeWithName:@"jid" stringValue:self.bookmarkedRooms[i]];
            [conference addAttributeWithName:@"nick" stringValue:self.nickName];
            
            [storage addChild:conference];
        }
    }
    
    [self.privateStorage savePrivateStorageWithElement:storage];
}



#pragma mark 为房间设置标签
- (void)addBookmarkToRoomName:(NSString *)roomName isAutoJoin:(BOOL)autoJoin roomJid:(NSString *)roomJID nickname:(NSString *)nickName
{
    [self getBookmarkRooms];
    
    self.roomName = roomName;
    self.roomJID = roomJID;
    self.nickName = nickName;
}

#pragma mark 删除制定房间标签
- (void)removeBookmarkRoomJid:(NSString *)roomJid
{
    [self getBookmarkRooms];
    self.removeRoomJid = roomJid;
}


#pragma mark 获取当前用户所有标签的房间
- (void)getBookmarkRooms
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage" xmlns:@"storage:bookmarks"];
    
    [self.privateStorage getPrivateStorateForElement:storage];
}






@end
