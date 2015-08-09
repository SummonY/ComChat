//
//  RoomMembersListViewController.m
//  ComChat
//
//  Created by D404 on 15/6/23.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomMembersListViewController.h"
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import "ChatViewController.h"
#import "UserListCell.h"
#import "InviteUserViewController.h"


@interface RoomMembersListViewController ()

@property (nonatomic, strong) NSString *roomJID;

@property (nonatomic, assign) BOOL isRoomOwnerOrAdmin;

@end

@implementation RoomMembersListViewController



#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [searchBar setPlaceholder:@"搜索"];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
}


#pragma mark 初始化
- (instancetype)initWithRoomJid:(NSString *)roomJid
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.roomsViewModel = [RoomsViewModel sharedViewModel];
        
        self.roomJID = roomJid;
        
        @weakify(self)
        [self.roomsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDataNotify)
                                                     name:@"ROOM_MEMBERS_LIST_RELOAD_DATA"
                                                   object:nil];
    }
    return self;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setHidesBottomBarWhenPushed:NO];
    [super viewWillAppear:animated];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* 设置导航条 */
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"群组成员";
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchMembersListAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    //[self fetchMembersListAction];
    
    self.isRoomOwnerOrAdmin = [self judegeRoomOwnerOrAdmin];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark 刷新数据
- (void)reloadDataNotify
{
    [self.tableView reloadData];
}


#pragma mark 刷新获取群组成员列表
- (void)fetchMembersListAction
{
    NSLog(@"刷新获取成员列表...");
    [self.roomsViewModel fetchRoomMembersList:self.roomJID];
    [self.refreshControl endRefreshing];
}


#pragma mark 判断自己是否为群组拥有者或管理员
- (BOOL)judegeRoomOwnerOrAdmin
{
    return [self.roomsViewModel isRoomOwnerOrAdmin:self.roomJID];
}





/////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
/////////////////////////////////////////////////////////////////

#pragma mark 岗位个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.roomsViewModel numberOfSectionsOfRoomAffiliation];
}

#pragma mark 岗位名称
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.roomsViewModel titleForHeaderInRoomAffiliationSection:section];
}

#pragma mark 每个岗位的用户个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.roomsViewModel numberOfRoomAffiliationInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIndentifier = @"RoomMemberCell";
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIndentifier];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier forIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:@"add_friend_nor"];
        cell.textLabel.text = @"邀请好友";
        
        return cell;
    }
    else {
        static NSString *UserListCellIdentifier = @"UserListCell";
        
        id object = [self.roomsViewModel objectAtRoomAffiliationIndexPath:indexPath];
        UserListCell *userListCell = [tableView dequeueReusableCellWithIdentifier:UserListCellIdentifier];
        
        if (!userListCell) {
            userListCell = [[UserListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:UserListCellIdentifier];
        }

        [(UserListCell *)userListCell shouldUpdateCellWithRoomMembersObject:object];
        return userListCell;
    }
}

#pragma mark 选中行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        //InviteUserViewController *inviteUserViewController = [[InviteUserViewController alloc] initWithStyle:UITableViewStyleGrouped];
        InviteUserViewController *inviteUserViewController = [[InviteUserViewController alloc] init];
        [inviteUserViewController initWithRoom:self.roomJID];
        [self.navigationController pushViewController:inviteUserViewController animated:YES];
    } else {            // TODO:
        id object = [self.roomsViewModel objectAtRoomAffiliationIndexPath:indexPath];
        NSString *userJID = (NSString *)object;
        XMPPJID *userJid = [XMPPJID jidWithString:userJID];
        ChatViewController *chatViewController = [[ChatViewController alloc] initWithBuddyJID:userJid buddyName:[self getUserName:userJID]];
        [self.navigationController pushViewController:chatViewController animated:YES];
    }
}

#pragma mark 根据用户JID获取用户名
- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}

#pragma mark 用户行高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

#pragma mark 用户分组高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0.0f;
    }
    return 20.f;
}



@end
