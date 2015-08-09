//
//  BookmarkManager.h
//  XEP-0048
//
//  Created by D404 on 15/7/8.
//
//

#define _XMPP_BOOKMARK_H

#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "XMPPModule.h"

@interface XMPPBookmark : XMPPModule


- (void)addBookmarkToRoomName:(NSString *)roomName isAutoJoin:(BOOL)autoJoin roomJid:(NSString *)roomJID nickname:(NSString *)nickName;
- (void)getBookmarkRooms;



@end
