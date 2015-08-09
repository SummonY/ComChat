//
//  GroupsViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomsViewModel.h"
#import <RACSubject.h>
#import <ReactiveCocoa.h>
#import <XMPPRoomCoreDataStorage.h>
#import "Macros.h"
#import "XMPP+IM.h"
#import <XMPPPubSub.h>
#import "XMPPBookmarkManager.h"
#import "XMPPRoomManager.h"


@interface RoomsViewModel()<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) XMPPRoomCoreDataStorage *roomCoreDataStorage;


@property (nonatomic, strong) NSString *createRoomJID;
@property (nonatomic, strong) NSString *joinRoomJID;
@property (nonatomic, strong) NSString *roomName;

@property (nonatomic, strong) RACSubject *updatedContentSignal;
@property (nonatomic, strong) NSMutableArray *roomsModel;

@property (nonatomic, strong) NSMutableDictionary *roomMembersModel;

@property (nonatomic, strong) NSMutableArray *roomOwners;
@property (nonatomic, strong) NSMutableArray *roomAdmins;
@property (nonatomic, strong) NSMutableArray *roomMembers;

@property (nonatomic, assign) BOOL isCreate;                    // 1:创建群组 0:加入群组

@property (nonatomic, strong) NSMutableArray *roomsSearchModel;
@property (nonatomic, strong) NSMutableArray *allRooms;
@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, strong) NSString *filterString;

@property (nonatomic, assign) BOOL isAddBookmark;
@property (nonatomic, strong) NSMutableArray *roomsBookmarked;

@property (nonatomic, assign) BOOL isRemoveBookmark;

@property (nonatomic, strong) NSMutableDictionary *roomInfoDictionary;

@end


@implementation RoomsViewModel


#pragma mark 共享View Model
+ (instancetype)sharedViewModel
{
    static RoomsViewModel *_shareedViewModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _shareedViewModel = [[self alloc] init];
    });
    return _shareedViewModel;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 初始化
- (instancetype)init
{
    if (self = [super init]) {
        self.roomContext = [[XMPPManager sharedManager] managedObjectContext_room];
        
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        self.updatedContentSignal = [[RACSubject subject] setNameWithFormat:@"%@updatedContentSignal", NSStringFromClass([RoomsViewModel class])];
        
        @weakify(self)
        [self.didBecomeActiveSignal subscribeNext:^(id x) {
            @strongify(self)
            //[self fetchRoomsList];
            //[self fetchRooms];
            [self fetchRoomsFromCoreData];
        }];
        
        RAC(self, active) = [RACObserve([XMPPManager sharedManager], myJID) map:^id(id value) {
            if (value) {
                return @(YES);
            }
            return @(NO);
        }];
    }
    return self;
}


#pragma mark 获取群组列表
- (void)fetchRoomsList
{
    NSLog(@"获取群组列表List...");
    
    XMPPJID *serverJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"conference.%@", XMPP_DOMAIN]];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}

#pragma mark 获取群组条目
- (void)fetchRoomItems:(NSString *)roomJID
{
    NSLog(@"获取%@群组条目...", roomJID);
    
    XMPPJID *serverJID = [XMPPJID jidWithString:roomJID];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 获取指定群组详细信息
- (void)fetchRoomsInfo:(NSString *)roomJID
{
    NSLog(@"获取群组:%@信息...", roomJID);
    
    XMPPJID *JID = [XMPPJID jidWithString:roomJID];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:JID];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#info"];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 获取联系人群组
- (void)fetchRoomsFromCoreData
{
    NSLog(@"联系人获取房间...");
    
    NSError *error = nil;
    if (![self.fetchedRoomsResultsController performFetch:&error]) {
        NSLog(@"获取联系人房间失败");
    }
    else {
        NSArray *dataArray = [self.fetchedRoomsResultsController fetchedObjects];
        if (dataArray.count > 0) {
            if (!self.roomsModel) {
                self.roomsModel = [[NSMutableArray alloc] initWithArray:dataArray];
            } else {
                [self.roomsModel setArray:dataArray];
            }
        }
        [(RACSubject *)self.updatedContentSignal sendNext:nil];
    }
}


#pragma mark 搜索群组
- (void)searchRooms:(NSString *)searchTerm
{
    NSLog(@"搜索群组...");
    
    self.isSearch = YES;
    self.filterString = [NSString stringWithFormat:@"%@", searchTerm];
    
    XMPPJID *serverJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"conference.%@", XMPP_DOMAIN]];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 获取群组成员列表
- (void)fetchRoomMembersList:(NSString *)roomJID
{
    NSLog(@"获取%@群组成员列表...", roomJID);
    
    XMPPJID *roomJid = [XMPPJID jidWithString:roomJID];
    XMPPRoomMemoryStorage *xmppRoomMemoryStorage = [[XMPPRoomMemoryStorage alloc] init];
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomMemoryStorage jid:roomJid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    
    self.roomOwners = [[NSMutableArray alloc] init];
    self.roomAdmins = [[NSMutableArray alloc] init];
    self.roomMembers = [[NSMutableArray alloc] init];
    
    [self fetchOwnersList:roomJid];     // 获取创建者列表
    [self fetchAdminsList:roomJid];     // 获取管理员列表
    [_xmppRoom fetchMembersList];       // 获取成员列表
}


#pragma mark 获取群组
- (NSFetchedResultsController *)fetchedRoomsResultsController
{
    NSLog(@"获取群组...");
    if (!_fetchedRoomsResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomOccupantCoreDataStorageObject" inManagedObjectContext:self.roomContext];
        
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"roomJIDStr" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        _fetchedRoomsResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.roomContext sectionNameKeyPath:nil cacheName:nil];
        [_fetchedRoomsResultsController setDelegate:self];
        
    }
    return _fetchedRoomsResultsController;
}


#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    self.roomsModel = [NSMutableArray arrayWithArray:[controller fetchedObjects]];
    [(RACSubject *)self.updatedContentSignal sendNext:nil];
}


#pragma mark 邀请好友加入群组
- (void)inviteUser:(NSString *)userJID inRoom:(NSString *)roomJID
{
    NSLog(@"邀请好友%@,到房间：%@", userJID, roomJID);
    
    XMPPJID *roomJid = [XMPPJID jidWithString:roomJID];
    XMPPRoomMemoryStorage *xmppRoomMemoryStorage = [[XMPPRoomMemoryStorage alloc] init];
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomMemoryStorage jid:roomJid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    XMPPJID *userJid = [XMPPJID jidWithString:userJID];
    
    [_xmppRoom inviteUser:userJid withMessage:[NSString stringWithFormat:@"Welcom to %@", roomJID]];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [message addAttributeWithName:@"to" stringValue:roomJID];
    [message addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"http://jabber.org/protocol/muc#user"];
    NSXMLElement *invite = [NSXMLElement elementWithName:@"invite"];
    [invite addAttributeWithName:@"to" stringValue:userJID];
    
    NSXMLElement *reason = [NSXMLElement elementWithName:@"reason"];
    [reason setStringValue:[NSString stringWithFormat:@"Welcom to join us!"]];
    
    [invite addChild:reason];
    [x addChild:invite];
    [message addChild:x];
    
    [[XMPPManager sharedManager].xmppStream sendElement:message];
}



/////////////////////////////////////////////////////////////////////////////
#pragma mark DataSource
/////////////////////////////////////////////////////////////////////////////


#pragma mark 用户分组数
- (NSInteger)numberOfSections
{
    return 1;
}


#pragma mark 每个分组的群组数目
- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.roomsModel count];
}


#pragma mark 返回section对应用户组
- (id)objectAtSection:(NSInteger)section
{
    NSDictionary *roomDic = [self.roomsModel objectAtIndex:section];
    return roomDic;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *roomDic = [self.roomsModel objectAtIndex:indexPath.row];
    
    return roomDic;
}



/////////////////////////////////////////////////////////////////////////////
#pragma mark DataSource
/////////////////////////////////////////////////////////////////////////////

#pragma mark 每个分组的群组数目
- (NSInteger)numberOfRoomsBookmarkedInSection:(NSInteger)section
{
    return [self.roomsBookmarked count];
}


- (id)objectOfRoomsBookmarkedAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *roomJid = [self.roomsBookmarked objectAtIndex:indexPath.row];
    
    return roomJid;
}


/////////////////////////////////////////////////////////////////////////////
#pragma mark Search DataSource
/////////////////////////////////////////////////////////////////////////////


#pragma mark 搜索群组
- (NSInteger)numberOfSearchItemsInSection:(NSInteger)section
{
    return [self.roomsSearchModel count];
}


- (id)objectAtSearchIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *roomDic = [self.roomsSearchModel objectAtIndex:indexPath.row];
    return roomDic;
}


/////////////////////////////////////////////////////////////////////////////
#pragma mark Room Members List DataSource
/////////////////////////////////////////////////////////////////////////////

#pragma mark 获取群组成员总个数
- (NSInteger)totalNumbersOfRoomAffiliation
{
    NSLog(@"总成员个数 : %u", self.roomOwners.count + self.roomAdmins.count + self.roomMembers.count);
    return self.roomOwners.count + self.roomAdmins.count + self.roomMembers.count;
}


#pragma mark Section个数
- (NSInteger)numberOfSectionsOfRoomAffiliation
{
    int count = 2;
    if (self.roomAdmins.count > 0) {
        count++;
    }
    if (self.roomMembers.count > 0) {
        count++;
    }
    
    return count;
}

#pragma mark Section标题
- (NSString *)titleForHeaderInRoomAffiliationSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else if (section == 1) {
        return @"群主";
    } else if (section == 2) {
        if (self.roomAdmins.count > 0) {
            return @"管理员";
        } else if (self.roomMembers.count > 0) {
            return @"成员";
        }
    } else if (section == 3) {
        return @"成员";
    }
    return nil;
}

#pragma mark 每个岗位成员个数
- (NSInteger)numberOfRoomAffiliationInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return [self.roomOwners count];
    } else if (section == 2) {
        if (self.roomAdmins.count > 0) {
            return [self.roomAdmins count];
        } else if (self.roomMembers.count > 0) {
            return [self.roomMembers count];
        } else
            return 0;
    } else if (section == 3) {
        return [self.roomMembers count];
    }
    return 0;
}

#pragma mark 获取每个岗位成员
- (id)objectAtRoomAffiliationIndexPath:(NSIndexPath *)indexPath
{
    NSString *userJid;
    if (indexPath.section == 1) {
        userJid = [self.roomOwners objectAtIndex:indexPath.row];;
    } else if (indexPath.section == 2) {
        if (self.roomAdmins.count > 0) {
            userJid = [self.roomAdmins objectAtIndex:indexPath.row];
        } else if (self.roomMembers.count > 0) {
            userJid = [self.roomMembers objectAtIndex:indexPath.row];
        }
    } else if (indexPath.section == 3) {
        userJid = [self.roomMembers objectAtIndex:indexPath.row];
    } else {
        return nil;
    }
    return userJid;
}


/////////////////////////////////////////////////////////////////////////////////
#pragma mark - Support XMPPRoomDelegate
/////////////////////////////////////////////////////////////////////////////////


#pragma mark 创建群组
- (void)createRoomWithRoomName:(NSString *)roomName
{
    NSLog(@"创建群组:%@", roomName);
    self.isCreate = YES;
    
    NSString *roomJID = [NSString stringWithFormat:@"%@@conference.%@", roomName, XMPP_DOMAIN];
    self.createRoomJID = [NSString stringWithFormat:@"%@", roomJID];
    XMPPJID *roomJid = [XMPPJID jidWithString:roomJID];
    
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:roomJid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    [_xmppRoom joinRoomUsingNickname:[XMPPManager sharedManager].myJID.bare history:nil];
    
    // 为新房间创建标签
    [self createBookmarkForRoom:roomJID];
    
    [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
}


- (NSString *)getRoomName:(NSString *)roomJID
{
    NSString *roomName = [NSString stringWithFormat:@"%@", [roomJID componentsSeparatedByString:@"@"][0]];
    return roomName;
}




#pragma mark 注册房间
- (void)registerRoomWithRoomJID:(NSString *)roomJid
{
    self.joinRoomJID = [NSString stringWithFormat:@"%@", roomJid];
    [[XMPPRoomManager sharedManager] requestRegisterToRoom:roomJid];        // 请求注册房间
}



#pragma mark 加入群组
- (void)joinRoomWithRoomJID:(NSString *)roomJid
{
    NSLog(@"申请加入群组:%@", roomJid);
    self.isCreate = NO;
    
    XMPPJID *jid = [XMPPJID jidWithString:roomJid];
    
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [_xmppRoom joinRoomUsingNickname:[XMPPManager sharedManager].myJID.bare history:nil];
    
    // 为加入房间创建标签                                // 设置只有当群主或管理员同意时才能添加标签
    [self createBookmarkForRoom:roomJid];
}


#pragma mark 退出群组
- (void)leaveRoomWithRoomJID:(NSString *)roomJid
{
    NSLog(@"退出群组:%@...", roomJid);
    // 删除房间标签
    self.isRemoveBookmark = YES;
    [[XMPPBookmarkManager sharedManager] removeBookmarkRoomJid:roomJid];
    
    //self.roomJID = [NSString stringWithFormat:@"%@", roomJid];
    XMPPJID *jid = [XMPPJID jidWithString:roomJid];
    
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    [_xmppRoom leaveRoom];
    [_xmppRoom deactivate];
    [_xmppRoom removeDelegate:self];
    _xmppRoom = nil;
}


#pragma mark 房间创建者销毁房间
- (void)destoryRoomWithRoomJID:(NSString *)roomJid
{
    NSLog(@"销毁房间%@...", roomJid);
    
    self.isRemoveBookmark = YES;
    [[XMPPBookmarkManager sharedManager] removeBookmarkRoomJid:roomJid];
    
    XMPPJID *jid = [XMPPJID jidWithString:roomJid];
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    [_xmppRoom destroyRoom];
    [_xmppRoom deactivate];
    [_xmppRoom removeDelegate:self];
    _xmppRoom = nil;
}


#pragma mark 加入所有已添加标签群组
- (void)joinAllBookmarkedRooms
{
    NSLog(@"加入所有添加标签群组...");
    
    for (int i = 0; i < self.roomsBookmarked.count; ++i) {
        NSString *roomJid = self.roomsBookmarked[i];
        XMPPJID *jid = [XMPPJID jidWithString:roomJid];
        
        _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:jid dispatchQueue:dispatch_get_main_queue()];
        [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
        if (![_xmppRoom isJoined]) {
            [_xmppRoom joinRoomUsingNickname:[XMPPManager sharedManager].myJID.bare history:nil];
        }
    }
}


/*
#pragma mark 通过pubsub方式, 为房间创建标签，用于只获取自身创建或加入的房间
- (void)createBookmarkForRoom:(NSString *)roomJid
{
    NSLog(@"为房间%@创建标签...", roomJid);
    
    NSXMLElement *pubsub = [[NSXMLElement alloc] initWithName:@"pubsub" xmlns:@"http://jabber.org/protocol/pubsub"];
    NSXMLElement *publish = [[NSXMLElement alloc] initWithName:@"publish"];
    [publish addAttributeWithName:@"node" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *item = [[NSXMLElement alloc] initWithName:@"item"];
    [item addAttributeWithName:@"id" stringValue:@"current"];
    
    NSXMLElement *storage = [DDXMLNode elementWithName:@"storage"];
    [storage addAttributeWithName:@"xmlns" stringValue:@"storage:bookmarks"];
    
    NSXMLElement *conference = [DDXMLNode elementWithName:@"conference"];
    [conference addAttributeWithName:@"name" stringValue:[NSString stringWithFormat:@"%@_RoomBookmark", roomJid]];
    [conference addAttributeWithName:@"autojoin" stringValue:@"true"];
    [conference addAttributeWithName:@"jid" stringValue:roomJid];
    
    NSXMLElement *nick = [[NSXMLElement alloc] initWithName:@"nick" stringValue:@"satish"];
    [conference addChild:nick];
    
    [storage addChild:conference];
    [item addChild:storage];
    [publish addChild:item];
    
    NSXMLElement *publish_options = [[NSXMLElement alloc] initWithName:@"publish-options"];
    NSXMLElement *x = [[NSXMLElement alloc] initWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"submit"];
    
    NSXMLElement *field1 = [NSXMLElement elementWithName:@"field"];
    [field1 addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [field1 addAttributeWithName:@"type" stringValue:@"hidden"];
    NSXMLElement *value1 = [[NSXMLElement alloc] initWithName:@"value" stringValue:@"http://jabber.org/protocol/pubsub#publish-options"];
    [field1 addChild:value1];
    [x addChild:field1];
    
    NSXMLElement *field2 = [NSXMLElement elementWithName:@"field"];
    [field2 addAttributeWithName:@"var" stringValue:@"pubsub#persist_items"];
    NSXMLElement *value2 = [[NSXMLElement alloc] initWithName:@"value" stringValue:@"true"];
    [field2 addChild:value2];
    [x addChild:field2];
    
    NSXMLElement *field3 = [NSXMLElement elementWithName:@"field"];
    [field3 addAttributeWithName:@"var" stringValue:@"pubsub#access_model"];
    NSXMLElement *value3 = [[NSXMLElement alloc] initWithName:@"value" stringValue:@"whitelist"];
    [field3 addChild:value3];
    [x addChild:field3];
    
    [publish_options addChild:x];
    [pubsub addChild:publish];
    [pubsub addChild:publish_options];
    
    //NSDictionary *options = [NSDictionary dictionaryWithObjects:@[@"pubsub#persist_items", @"pubsub#access_model"] forKeys:@[@"true", @"whitelist"]];
    
    //NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:private"];
    //[query addChild:storage];
    
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"set" child:pubsub];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.bare];
    [iq addAttributeWithName:@"id" stringValue:@"pip1"];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
    
    //XMPPPubSub *publishSubscribeModule = [[XMPPPubSub alloc] init];
    //[publishSubscribeModule publishToNode:@"storage:bookmarks" entry:(NSXMLElement *)storage withItemID:(NSString *)@"current" options:(NSDictionary *)options];
}



#pragma mark 获取群组标签
- (void)fetchRoomBookmarks
{
    DDXMLElement *pubsub = [DDXMLElement elementWithName:@"pubsub" xmlns:@"http://jabber.org/protocol/pubsub"];
    DDXMLElement *items = [DDXMLElement elementWithName:@"items"];
    [items addAttributeWithName:@"node" stringValue:@"storage:bookmarks"];
    [pubsub addChild:items];
    
    XMPPIQ *iq = [[XMPPIQ alloc] initWithType:@"get" child:pubsub];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.bare];
    [iq addAttributeWithName:@"id" stringValue:@"retrieve1"];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}
*/


#pragma mark 为房间创建标签，用于只获取自身创建或加入的房间
- (void)createBookmarkForRoom:(NSString *)roomJid
{
    NSLog(@"为房间%@创建标签...", roomJid);
    
    self.isAddBookmark = YES;
    [[XMPPBookmarkManager sharedManager] addBookmarkToRoomName:roomJid isAutoJoin:YES roomJid:roomJid nickname:[XMPPManager sharedManager].myJID.bare];
}


#pragma mark 获取群组标签
- (void)fetchRoomBookmarks
{
    NSLog(@"获取以添加标签群组...");
    
    self.isAddBookmark = NO;
    [[XMPPBookmarkManager sharedManager] getBookmarkRooms];
}


#pragma mark 判断用户是否在该指定群组
- (BOOL)isExistedInRoomJid:(NSString *)roomJid
{
    for (NSString *roomJID in self.roomsBookmarked) {
        if ([roomJID isEqualToString:roomJid]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark 判断用户是否为群组拥有者
- (BOOL)isRoomOwner:(NSString *)userJid
{
    if (self.roomOwners.count > 0) {
        if ([self.roomOwners[0] isEqualToString:userJid]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark 判断用户是否为房间拥有者或管理员
- (BOOL)isRoomOwnerOrAdmin:(NSString *)userJid
{
    if ((self.roomOwners.count > 0) && (self.roomAdmins.count > 0)) {
        if (([self.roomOwners[0] isEqualToString:userJid])) {
            return YES;
        }
    }
    return NO;
}


#pragma mark 对新创建的群组进行配置
- (void)configNewXmppRoom
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    NSXMLElement *p;
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];   // 永久房间
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
//    p = [NSXMLElement elementWithName:@"field"];
//    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_memberonly"];       // 仅对成员开放
//    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
//    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_maxusers"];         // 群组最大用户
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"500"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_changesubject"];    // 允许改变主题
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_publicroom"];       // 公共房间
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_allowinvites"];     // 允许邀请
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_enablelogging"];     // 允许登录房间对话
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_getmemberlist"];     // 允许获取成员列表
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"moderator"]];
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"participant"]];
    [p addChild:[NSXMLElement elementWithName:@"value" xmlns:@"visitor"]];
    [x addChild:p];
    
    XMPPJID *roomjid = [XMPPJID jidWithString:self.createRoomJID];
    _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPManager sharedManager].xmppRoomCoreDataStorage jid:roomjid dispatchQueue:dispatch_get_main_queue()];
    [_xmppRoom activate:[XMPPManager sharedManager].xmppStream];
    [_xmppRoom configureRoomUsingOptions:x];
}


#pragma mark 对用户加入群组进行配置
- (void)configJoinXmppRoom
{
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    NSXMLElement *p;
    
    p = [NSXMLElement elementWithName:@"field"];
    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];   // 永久房间
    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
    [x addChild:p];
    
//    p = [NSXMLElement elementWithName:@"field"];
//    [p addAttributeWithName:@"var" stringValue:@"muc#roomconfig_membersonly"];       // 仅对成员开放
//    [p addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
//    [x addChild:p];
    
    [_xmppRoom configureRoomUsingOptions:x];
}


#pragma mark 不发送历史消息
- (void)noSendHistory
{
    XMPPPresence *y = [[XMPPPresence alloc] initWithType:@"" to:[XMPPJID jidWithString:self.joinRoomJID]];
    [y addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [y removeAttributeForName:@"type"];
    
    NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"http://jabber.org/protocol/muc"];
    NSXMLElement *p = [NSXMLElement elementWithName:@"history"];
    [p addAttributeWithName:@"maxchars" stringValue:@"0"];
    [x addChild:p];
    [y addChild:x];
    [[XMPPManager sharedManager].xmppStream sendElement:y];
}


#pragma mark 获取拥有者列表
- (void)fetchOwnersList:(XMPPJID *)roomJID
{
    // <iq type='get'
    //       id='member3'
    //       to='coven@chat.shakespeare.lit'>
    //   <query xmlns='http://jabber.org/protocol/muc#admin'>
    //     <item affiliation='owner'/>
    //   </query>
    // </iq>
    
    NSString *fetchID = [[XMPPManager sharedManager].xmppStream generateUUID];
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"owner"];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}

#pragma mark 获取管理员列表
- (void)fetchAdminsList:(XMPPJID *)roomJID
{
    
    // <iq type='get'
    //       id='member3'
    //       to='coven@chat.shakespeare.lit'>
    //   <query xmlns='http://jabber.org/protocol/muc#admin'>
    //     <item affiliation='admin'/>
    //   </query>
    // </iq>
    
    NSString *fetchID = [[XMPPManager sharedManager].xmppStream generateUUID];
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"admin"];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:roomJID elementID:fetchID child:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


//////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
//////////////////////////////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"RoomsViewModel接收到IQ包%@", iq);
    if ([iq isChatRoomItems]) {
        if (self.isSearch) {
            NSXMLElement *element = iq.childElement;
            self.roomsSearchModel = [[NSMutableArray alloc] init];
            
            for (NSXMLElement *item in element.children) {
                NSMutableDictionary *roomDic = [[NSMutableDictionary alloc] init];
                NSString *roomJid = item.attributesAsDictionary[@"jid"];
                NSString *roomName = item.attributesAsDictionary[@"name"];
                if ([roomName rangeOfString:self.filterString].location != NSNotFound) {
                    [roomDic addEntriesFromDictionary:@{roomJid : roomName}];
                    [self.roomsSearchModel addObject:roomDic];
                }
            }
            self.isSearch = NO;
            NSLog(@"搜索到的群组:%@", self.roomsSearchModel);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SEARCH_GROUP_RELOAD_DATA" object:self userInfo:nil];
            return YES;
        }
        
        NSXMLElement *element = iq.childElement;
        self.roomsModel = [[NSMutableArray alloc] initWithCapacity:element.children.count];
        
        for (NSXMLElement *item in element.children) {
            NSMutableDictionary *roomDic = [[NSMutableDictionary alloc] init];
            NSString *roomJid = item.attributesAsDictionary[@"jid"];
            NSString *roomName = item.attributesAsDictionary[@"name"];
            [roomDic addEntriesFromDictionary:@{roomJid : roomName}];
            [self.roomsModel addObject:roomDic];
        }
        NSLog(@"所有群组 = %@", self.roomsModel);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ROOMS_LIST_RELOAD_DATA" object:self userInfo:nil];
    } else if ([iq isChatRoomInfo]) {
        self.roomInfoDictionary = [[NSMutableDictionary alloc] init];
        for (NSXMLElement *element in iq.childElement.children) {
            if ([element.name isEqualToString:@"x"]) {
                for (NSXMLElement *field in element.children) {
                    if (field.childCount > 0) {
                        for (NSXMLElement *value in field.children) {
                            [self.roomInfoDictionary addEntriesFromDictionary:@{field.attributesAsDictionary[@"var"] : [value stringValue]}];
                        }
                    } else {
                        [self.roomInfoDictionary addEntriesFromDictionary:@{field.attributesAsDictionary[@"var"] : @""}];
                    }
                    
                }
                NSLog(@"room info = %@", self.roomInfoDictionary);
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ROOM_INFO_RELOAD_DATA" object:self userInfo:@{@"roomName" : self.roomInfoDictionary[@"muc#roominfo_description"], @"occupants" : self.roomInfoDictionary[@"muc#roominfo_occupants"], @"subject" : self.roomInfoDictionary[@"muc#roominfo_subject"], @"creationdate" : self.roomInfoDictionary[@"x-muc#roominfo_creationdate"]}];
        
    } else if ([iq isFetchMembersList]) {       // 获取群组成员列表
        if ([iq.attributesAsDictionary[@"type"] isEqualToString:@"result"]) {
            NSXMLElement *element = iq.childElement;
            
            for (NSXMLElement *item in element.children) {
                //NSMutableDictionary *userDic = [[NSMutableDictionary alloc] init];
                NSString *userJid = item.attributesAsDictionary[@"jid"];
                NSString *userAffiliation = item.attributesAsDictionary[@"affiliation"];
                //[userDic addEntriesFromDictionary:@{userJid : userAffiliation}];
                if ([userAffiliation isEqualToString:@"owner"]) {
                    [self.roomOwners addObject:userJid];
                } else if ([userAffiliation isEqualToString:@"admin"]) {
                    [self.roomAdmins addObject:userJid];
                } else if ([userAffiliation isEqualToString:@"member"]) {
                    [self.roomMembers addObject:userJid];
                }
            }
            NSLog(@"群组成员列表: owner : %@, admins = %@, members = %@", self.roomOwners, self.roomAdmins, self.roomMembers);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ROOM_MEMBERS_LIST_RELOAD_DATA" object:self userInfo:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ROOM_MEMBERS_TOTAL_RELOAD_DATA" object:self userInfo:nil];
        }
    } else if([iq isRoomBookmarks]) {
        NSXMLElement *element = iq.childElement;
        
        self.roomsBookmarked = [[NSMutableArray alloc] init];
        [XMPPBookmarkManager sharedManager].bookmarkedRooms = [[NSMutableArray alloc] init];
        for (NSXMLElement *storage in element.children) {
            for (NSXMLElement *conference in storage.children) {
                NSString *roomJid = [NSString stringWithFormat:@"%@", conference.attributesAsDictionary[@"jid"]];
                [[XMPPBookmarkManager sharedManager].bookmarkedRooms addObject:roomJid];
                [self.roomsBookmarked addObject:roomJid];
            }
            if (self.isAddBookmark) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ADD_BOOK_MARK_NOTIFY" object:self userInfo:nil];
                self.isAddBookmark = NO;
            }
            
            if (self.isRemoveBookmark) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"REMOVE_BOOK_MARK_NOTIFY" object:self userInfo:nil];
                self.isRemoveBookmark = NO;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ROOMS_LIST_RELOAD_DATA" object:self userInfo:nil];
            NSLog(@"已添加标签群组:%@", [XMPPBookmarkManager sharedManager].bookmarkedRooms);
            [self joinAllBookmarkedRooms];
        }
    } else if ([iq isRoomRegisterQuery:self.joinRoomJID]) {
        NSLog(@"接收到注册请求清单...");
        if (![[iq type] isEqualToString:@"error"]) {
            NSString *roomJid = [iq from].full;
            [[XMPPRoomManager sharedManager] commitRegisterFormToRoom:roomJid withNickname:[XMPPManager sharedManager].myJID.bare];
        }
    } else if ([iq isRoomRegisterCommitResult:self.joinRoomJID]) {
        NSLog(@"接收到房间注册提交结果.");
        if (![[iq type] isEqualToString:@"error"]) {
            [self joinRoomWithRoomJID:self.joinRoomJID];
        }
    }
    return YES;
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"RoomsViewModel xmppStream接收到presence,%@", presence);
    
    if ([presence isApplyToJoinRoom]) {
        NSString *roomJid = [self getJid:presence.attributesAsDictionary[@"from"]];
        NSString *userJid;
        for (NSXMLElement *element in presence.children) {
            if ([element.name isEqualToString:@"x"] && [element.xmlns isEqualToString:@"http://jabber.org/protocol/muc#user"]) {
                for (NSXMLElement *item in element.children) {
                    userJid = [self getJid:item.attributesAsDictionary[@"jid"]];
                }
            }
        }
        NSLog(@"用户：%@，请求加入群组：%@\nTODO: 管理员为该用户分配岗位...", userJid, roomJid);
        
    }
}


- (NSString *)getJid:(NSString *)userJIDFull
{
    NSString *name = [NSString stringWithFormat:@"%@", [userJIDFull componentsSeparatedByString:@"/"][0]];
    return name;
}



///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRoomDelegate
///////////////////////////////////////////////////////////////////////////////////////////

#pragma mark 创建聊天室成功
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"RoomsViewModel xmppRoom聊天室已创建..., %@", sender);
}

/**
 * Invoked with the results of a request to fetch the configuration form.
 * The given config form will look something like:
 *
 * <x xmlns='jabber:x:data' type='form'>
 *   <title>Configuration for MUC Room</title>
 *   <field type='hidden'
 *           var='FORM_TYPE'>
 *     <value>http://jabber.org/protocol/muc#roomconfig</value>
 *   </field>
 *   <field label='Natural-Language Room Name'
 *           type='text-single'
 *            var='muc#roomconfig_roomname'/>
 *   <field label='Enable Public Logging?'
 *           type='boolean'
 *            var='muc#roomconfig_enablelogging'>
 *     <value>0</value>
 *   </field>
 *   ...
 * </x>
 *
 * The form is to be filled out and then submitted via the configureRoomUsingOptions: method.
 *
 * @see fetchConfigurationForm:
 * @see configureRoomUsingOptions:
 **/
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    NSLog(@"RoomsViewModel xmppRoom获取到配置格式，%@", configForm);
    
    NSXMLElement *newConfig = [configForm copy];
    NSArray *fields = [newConfig elementsForName:@"field"];
    
    for (NSXMLElement *field in fields) {
        NSString *var = [field attributeStringValueForName:@"var"];
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
        }
    }
    [sender configureRoomUsingOptions:newConfig];
}

- (void)xmppRoom:(XMPPRoom *)sender willSendConfiguration:(XMPPIQ *)roomConfigForm
{
    NSLog(@"RoomsViewModel xmppRoom将要发送配置信息");
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"RoomsViewModel xmppRoom配置完成. %@", iqResult);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"RoomsViewModel xmppRoom配置失败, %@", iqResult);
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"RoomsViewModel xmppRoom已经加入群组, %@", sender);
    
    if (self.isCreate) {
        NSLog(@"对新创建的群组进行配置...");
        [self configNewXmppRoom];
    }
    else {
        [self noSendHistory];
        [self.xmppRoom configureRoomUsingOptions:nil];
        [self.xmppRoom fetchConfigurationForm];
        //[self configJoinXmppRoom];
    }
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender
{
    NSLog(@"RoomsViewModel xmppRoom已经离开群组, %@", sender);
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender
{
    NSLog(@"RoomsViewModel xmppRoom群组已解散, %@", sender);
}

#pragma mark 加入群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"RoomsViewModel xmppRoom occupant已经加入群组, JID = %@, presence = %@", occupantJID, presence);
    
}

#pragma mark 离开群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"RoomsViewModel xmppRoom occupant离开群组, JID = %@, presence = %@", occupantJID, presence);
}

#pragma mark 群组人员加入
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"RoomsViewModel xmppRoom occupant更新, JID = %@, presence = %@", occupantJID, presence);
    
}

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room, or from a non-occupant.
 **/
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    NSLog(@"RoomsViewModel xmppRoom接收到消息, message = %@, JID = %@", message, occupantJID);
    //XMPPRoomOccupantCoreDataStorageObject *occupant = [(XMPPRoomCoreDataStorage *)sender.xmppRoomStorage occupantForJID:[XMPPJID jidWithString:@""] stream:[XMPPManager sharedManager].xmppStream inContext:[[XMPPRoomCoreDataStorage sharedInstance] mainThreadManagedObjectContext]];
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
    NSLog(@"RoomsViewModel xmppRoom获取禁止名单列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError
{
    NSLog(@"RoomsViewModel xmppRoom获取禁止名单列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
    NSLog(@"RoomsViewModel xmppRoom获取成员列表成功, %@", items);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError
{
    NSLog(@"RoomsViewModel xmppRoom获取成员列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchAdminsList:(NSArray *)items
{
    NSLog(@"RoomsViewModel xmppRoom获取管理员列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchAdminsList:(XMPPIQ *)iqError
{
    NSLog(@"RoomsViewModel xmppRoom获取管理员列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
    NSLog(@"RoomsViewModel xmppRoom获取ModeratorsList成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError
{
    NSLog(@"RoomsViewModel xmppRoom获取ModeratorsList失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult
{
    NSLog(@"RoomsViewModel xmppRoom获取到BanList成功, %@", iqResult);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError
{
    NSLog(@"RoomsViewModel xmppRoom获取到BanList成功, %@", iqError);
}





///////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -XMPPRoomStorage Delegate
///////////////////////////////////////////////////////////////////////////////////////////////


- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    NSLog(@"RoomsViewModel XMPPRoomStorage Delegate 配置Parent：%@", aParent);
    return YES;
}

/**
 * Updates and returns the occupant for the given presence element.
 * If the presence type is "available", and the occupant doesn't already exist, then one should be created.
 **/
- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room
{
    NSLog(@"处理房间：%@的Presence消息：%@", room, presence);
}

/**
 * Stores or otherwise handles the given message element.
 **/
- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    NSLog(@"房间:%@处理Incoming消息:%@", room.roomJID, message);
}

- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    NSLog(@"房间：%@处理Outgoing消息:%@", room.roomJID, message);
}

/**
 * Handles leaving the room, which generally means clearing the list of occupants.
 **/
- (void)handleDidLeaveRoom:(XMPPRoom *)room
{
    NSLog(@"离开房间:%@", room.roomJID);
}


/**
 * May be used if there's anything special to do when joining a room.
 **/
- (void)handleDidJoinRoom:(XMPPRoom *)room withNickname:(NSString *)nickname
{
    NSLog(@"处理已经加入房间:%@，昵称：%@", room.roomJID, nickname);
}



@end
