//
//  BookmarkManager.m
//  Pods
//
//  Created by D404 on 15/7/8.
//
//

#import "XMPPBookmark.h"
#import "XMPPPrivateStorage.h"

@interface XMPPBookmark ()


@property (nonatomic, strong) XMPPPrivateStorage *privateStorage;


@end


@implementation XMPPBookmark


- (id)init
{
    if (self = [super init]) {
        self.privateStorage = [[XMPPPrivateStorage alloc] init];
    }
    return self;
}



#pragma mark 为房间设置标签
- (void)addBookmarkToRoomName:(NSString *)roomName isAutoJoin:(BOOL)autoJoin roomJid:(NSString *)roomJID nickname:(NSString *)nickName
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference = [NSXMLElement elementWithName:@"conference"];
    [conference addAttributeWithName:@"name" stringValue:[NSString stringWithFormat:@"%@", roomName]];
    [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
    [conference addAttributeWithName:@"jid" stringValue:roomJID];
    [conference addAttributeWithName:@"nick" stringValue:nickName];
    
    [storage addChild:conference];
    XMPPPrivateStorage *privateStorage = [[XMPPPrivateStorage alloc] init];
    [privateStorage getPrivateStorateForElement:storage];
}


#pragma mark 获取当前用户所有标签的房间
- (void)getBookmarkRooms
{
    NSXMLElement *storage = [NSXMLElement elementWithName:@"storage" xmlns:@"storage:bookmarks"];
   
    XMPPPrivateStorage *privateStorage = [[XMPPPrivateStorage alloc] init];
    [privateStorage getPrivateStorateForElement:storage];
}





@end
