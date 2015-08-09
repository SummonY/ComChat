//
//  MessageViewController.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "MessageViewController.h"
#import "XMPPManager.h"
#import "RTCManager.h"
#import "ChatViewController.h"
#import "GroupChatViewController.h"
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import "ProfileViewController.h"
#import "ModalAlert.h"
#import "RecentContactCell.h"
#import "RecentRoomsCell.h"
#import "XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.h"
#import "XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.h"


@interface MessageViewController ()<UISearchBarDelegate, UISearchDisplayDelegate> {
    UISearchDisplayController *searchDisplayController;
}

@property (nonatomic, assign) BOOL isRoomMessage;


@end


@implementation MessageViewController


#pragma mark 初始化样式
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.messageViewModel = [MessageViewModel sharedViewModel];
        
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        @weakify(self);
        [self.messageViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetCurrentContactUnreadMessagesCountNofity:)
                                                     name:@"RESET_CURRENT_CONTACT_UNREAD_MESSAGES_COUNT"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetCurrentRoomUnreadMessagesCountNofity:)
                                                     name:@"RESET_CURRENT_ROOM_UNREAD_MESSAGES_COUNT"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [searchBar setPlaceholder:@"搜索"];
    self.tableView.tableHeaderView = searchBar;
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"消息";
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"user_head_little"] style:UIBarButtonItemStylePlain target:self action:@selector(profileSetting:)] animated:YES];

    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchContactsAndRoomsMessageAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self fetchContactsAndRoomsMessageAction];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 重置当前联系人未读消息数
- (void)resetCurrentContactUnreadMessagesCountNofity:(NSNotification *)nofify
{
    id object = nofify.object;
    if ([object isKindOfClass:[XMPPJID class]]) {
        XMPPJID *contactJid = (XMPPJID *)object;
        [self.messageViewModel resetUnreadMessageCountForCurrentContact:contactJid];
    }
}


#pragma mark 重置当前群组未读消息数
- (void)resetCurrentRoomUnreadMessagesCountNofity:(NSNotification *)nofify
{
    id object = nofify.object;
    if ([object isKindOfClass:[XMPPJID class]]) {
        XMPPJID *roomJid = (XMPPJID *)object;
        //[self.messageViewModel resetUnreadMessageCountForCurrentRoom:roomJid];
    }
}


#pragma mark 个人信息设置及查看
- (IBAction)profileSetting:(id)sender
{
    NSLog(@"查看及设置个人信息...");
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:profileViewController animated:YES];
}



#pragma mark 获取联系人消息
- (void)fetchContactsAndRoomsMessageAction
{
    NSLog(@"刷新获取联系人消息...");
    
    [self.messageViewModel fetchRecentContacts];                // 获取当前联系人
    [self.messageViewModel fetchRecentRooms];                   // 获取当前群组
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}




#pragma mark 获取XMPP消息打包模式
- (void)fetchXMPPArchiveMode
{
    NSLog(@"发送监测点请求...");
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
    
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    
    NSXMLElement *pref = [NSXMLElement elementWithName:@"pref" xmlns:@"urn:xmpp:archive"];
    
    [iq addChild:pref];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}


#pragma mark 获取用户历史消息记录
- (void)fetchMesageArchive
{
    NSLog(@"MessageArchive...");
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get"];
    [iq addAttributeWithName:@"id" stringValue:@"page1"];
    
    NSXMLElement *retrieve = [NSXMLElement elementWithName:@"retrieve" xmlns:@"urn:xmpp:archive"];
    [retrieve addAttributeWithName:@"with" stringValue:[NSString stringWithFormat:@"%@", [XMPPManager sharedManager].myJID.full]];
    [retrieve addAttributeWithName:@"start" stringValue:@"2015-06-01T02:56:15Z"];
    
    NSXMLElement *set = [NSXMLElement elementWithName:@"set" xmlns:@"http://jabber.org/protocol/rsm"];
    NSXMLElement *max = [NSXMLElement elementWithName:@"max"];
    [max setStringValue:@"100"];
    [set addChild:max];
    
    [retrieve addChild:set];
    
    [iq addChild:retrieve];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
    NSLog(@"News发送IQ包:%@", iq);
}




/////////////////////////////////////////////////////////////////////////////////////
#pragma mark Search Bar Delegate
/////////////////////////////////////////////////////////////////////////////////////

#pragma mark 点击搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索...");
    searchBar.showsCancelButton = YES;
}


#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}



//////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
//////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messageViewModel numberOfItemsInSection:section];
}


#pragma mark 设置当前联系人Cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self.messageViewModel objectAtIndexPath:indexPath];
    
    if ([object isKindOfClass:[XMPPMessageArchiving_Contact_CoreDataObject class]]) {
        static NSString *contactCellIdentifier = @"RecentContactCell";
        RecentContactCell *recentContactCell = [tableView dequeueReusableCellWithIdentifier:contactCellIdentifier];
        if (!recentContactCell) {
            recentContactCell = [[RecentContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:contactCellIdentifier];
        }
        
        XMPPMessageArchiving_Contact_CoreDataObject *contact = (XMPPMessageArchiving_Contact_CoreDataObject *)object;
        [recentContactCell shouldUpdateCellWithObject:contact];
        
        return recentContactCell;
    } else if ([object isKindOfClass:[XMPPRoomMessageCoreDataStorageObject class]]) {
        static NSString *roomCellIdentifier = @"RecentRoomsCell";
        RecentRoomsCell *recentRoomsCell = [tableView dequeueReusableCellWithIdentifier:roomCellIdentifier];
        if (!recentRoomsCell) {
            recentRoomsCell = [[RecentRoomsCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:roomCellIdentifier];
        }
        
        XMPPRoomMessageCoreDataStorageObject *roomMessage = (XMPPRoomMessageCoreDataStorageObject *)object;
        [recentRoomsCell shouldUpdateCellWithObject:roomMessage];
        
        return recentRoomsCell;
    } else if ([object isKindOfClass:[XMPPRoomOccupantCoreDataStorageObject class]]) {   // TODO: 验证到底是XMPPRoomMessage还是XMPPRoomOccupant
        static NSString *roomCellIdentifier = @"RecentRoomsCell";
        RecentRoomsCell *recentRoomsCell = [tableView dequeueReusableCellWithIdentifier:roomCellIdentifier];
        if (!recentRoomsCell) {
            recentRoomsCell = [[RecentRoomsCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:roomCellIdentifier];
        }
        
        XMPPRoomOccupantCoreDataStorageObject *roomMessage = (XMPPRoomOccupantCoreDataStorageObject *)object;
        [recentRoomsCell shouldUpdateCellWithObject:roomMessage];
        
        return recentRoomsCell;
    }
    return nil;
}


#pragma mark 设置Cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.messageViewModel deleteObjectAtIndexPath:indexPath];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.messageViewModel objectAtIndexPath:indexPath];
    
    if ([object isKindOfClass:[XMPPMessageArchiving_Contact_CoreDataObject class]]) {       // 单聊
        NSLog(@"进入一对一聊天...");
        
        //XMPPMessageArchiving_Contact_CoreDataObject *contact = [self.messageViewModel objectAtIndexPath:indexPath];
        XMPPMessageArchiving_Contact_CoreDataObject *contact = (XMPPMessageArchiving_Contact_CoreDataObject *)object;
        ChatViewController *chatViewController = [[ChatViewController alloc] initWithBuddyJID:contact.bareJid
                                                                                    buddyName:contact.displayName];
        [self.navigationController pushViewController:chatViewController animated:YES];
        
        // 重置联系人未读消息数
        if ([self.messageViewModel resetUnreadMessageCountForCurrentContact:contact.bareJid]) {
            if ([self.tableView numberOfSections] > indexPath.section
                && [self.tableView numberOfRowsInSection:indexPath.section] > indexPath.row) {
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    } else if ([object isKindOfClass:[XMPPRoomMessageCoreDataStorageObject class]]) {       // 群聊
        NSLog(@"进入群聊Message...");
        
        //XMPPRoomMessageCoreDataStorageObject *roomMessage = [self.messageViewModel objectAtIndexPath:indexPath];
        XMPPRoomMessageCoreDataStorageObject *roomMessage = (XMPPRoomMessageCoreDataStorageObject *)object;
        GroupChatViewController *groupChatViewController = [[GroupChatViewController alloc] initWithGroupJID:roomMessage.roomJID groupName:roomMessage.roomJIDStr];                 // TODO:改为群组名称
        [self.navigationController pushViewController:groupChatViewController animated:YES];
        
        /*
        // 重置群组未读消息数
        if ([self.messageViewModel resetUnreadMessageCountForCurrentRoom:roomMessage.roomJID]) {
            if ([self.tableView numberOfSections] > indexPath.section && [self.tableView numberOfRowsInSection:indexPath.section] > indexPath.row) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
         */
    } else if ([object isKindOfClass:[XMPPRoomOccupantCoreDataStorageObject class]]) {       // 群聊
        NSLog(@"进入群聊Occupant...");
        
        //XMPPRoomOccupantCoreDataStorageObject *roomMessage = [self.messageViewModel objectAtIndexPath:indexPath];
        XMPPRoomOccupantCoreDataStorageObject *roomOccupant = (XMPPRoomOccupantCoreDataStorageObject *)object;
        GroupChatViewController *groupChatViewController = [[GroupChatViewController alloc] initWithGroupJID:roomOccupant.roomJID groupName:[self getRoomName:roomOccupant.roomJID.bare]];
        [self.navigationController pushViewController:groupChatViewController animated:YES];
        
        /*
        // 重置群组未读消息数
        if ([self.messageViewModel resetUnreadMessageCountForCurrentRoom:roomMessage.roomJID]) {
            if ([self.tableView numberOfSections] > indexPath.section && [self.tableView numberOfRowsInSection:indexPath.section] > indexPath.row) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
         */
    }
    
}

#pragma mark 获取群组名称
- (NSString *)getRoomName:(NSString *)roomJID
{
    NSString *roomName = [NSString stringWithFormat:@"%@", [roomJID componentsSeparatedByString:@"@"][0]];
    return roomName;
}



#pragma mark 新消息到来插入一行
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}



/*

- (void)rtcManagerDidReceiveRTCTaskRequest:(RTCManager *)sender fromUser:(NSString *)bareJID
{
    NSLog(@"RTCVideoChatViewController 从用户:%@ 接收到RTC任务请求...", bareJID);
    
    BOOL flag = [ModalAlert ask:[NSString stringWithFormat:@"是否接受%@的视频请求?", bareJID]];
    
    if (flag) {
        [[RTCManager sharedManager] startRTCTaskAsInitiator:NO withTarget:bareJID];
    } else {
        NSDictionary *jsonDict = @{@"type" : @"bye"};
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
        NSAssert(!error, @"%@", [NSString stringWithFormat:@"Error : %@", error.description]);
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [[XMPPManager sharedManager] sendSignalingMessage:jsonStr toJID:bareJID];
    }
}
*/


//////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
//////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"MessageViewController xmppStream断开连接");
    
}


@end
