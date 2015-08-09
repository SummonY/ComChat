//
//  ContactsViewController.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ContactsViewController.h"
#import "XMPPManager.h"
#import "ChatViewController.h"
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import "ContactsHeaderView.h"
#import "NewFriendsViewController.h"
#import "ContactsSearchViewController.h"
#import "RoomsViewController.h"
#import "UserGroupCell.h"
#import "UserListCell.h"
#import "XMPPMessageArchiving_Contact_CoreDataObject+RecentContact.h"
#import "XMPP+IM.h"



@interface ContactsViewController () {
    NSMutableArray *selectedArr;    // 二级列表是否展开
}

@property (nonatomic, strong) ContactsHeaderView *contactsHeaderView;

@end

@implementation ContactsViewController


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark 初始化联系人界面
- (void)loadView
{
    [super loadView];
    
    self.contactsHeaderView = [[ContactsHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 120)];

    self.tableView.tableHeaderView = self.contactsHeaderView;
}

#pragma mark 初始化界面
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.contactsViewModel = [ContactsViewModel sharedViewModel];
        self.roomsViewModel = [RoomsViewModel sharedViewModel];         // 用于登录成功后自动加入群组
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        @weakify(self)
        [self.contactsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        //[[NSNotificationCenter defaultCenter] addObserver:self                                                 selector:@selector(resetUnsubcribeContactCountNofity:)                                                     name:@"RESET_UNSUBSCRIBE_CONTACT_COUNT"                                                   object:nil];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contactsHeaderView.delegate = self;
    
    /* 设置导航条 */
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"联系人";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_friend_nor"] style:UIBarButtonItemStylePlain target:self action:@selector(addFriends:)] animated:YES];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchContactsAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    // 判断二级列表是否展开
    selectedArr = [[NSMutableArray alloc] init];
    
    [self fetchContactsAction];
    
    [self.contactsHeaderView setUnsubscribedCountNum:self.contactsViewModel.unsubscribedCountNum];
    
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
}


#pragma mark 重置未添加联系人数目
- (void)resetUnsubcribeContactCountNofity:(NSNotification *)nofify
{
    id object = nofify.object;
    if ([object isKindOfClass:[XMPPJID class]]) {
        [self.contactsHeaderView setUnsubscribedCountNum:object];
    }
}


#pragma mark 点击添加好友
- (IBAction)addFriends:(id)sender
{
    NSLog(@"点击添加好友...");
    ContactsSearchViewController* contactsSearchViewContorller = [[ContactsSearchViewController alloc] init];
    [self.navigationController pushViewController:contactsSearchViewContorller animated:YES];
}

#pragma mark 刷新获取当前联系人状态
- (void)fetchContactsAction
{
    NSLog(@"刷新获取当前联系人状态...");
    //[self.contactsViewModel fetchGroups];
    // 获取所有用户
    [self.contactsViewModel fetchUsers];
    
    // 登录后加入所有群组
    [self.roomsViewModel fetchRoomBookmarks];
    
    [self.refreshControl endRefreshing];
}



/////////////////////////////////////////////////////////////
#pragma mark ContactHeader delegate
/////////////////////////////////////////////////////////////


#pragma mark 点击显示好友推荐
- (void)showAllAddressBook
{
    NSLog(@"显示好友推荐列表...");
    
}


#pragma mark 点击显示我的好友
- (void)showNewFriends
{
    NSLog(@"显示好友请求列表...");
    [self.contactsViewModel resetUnsubscribeContactCount];
    [self.contactsHeaderView resetUnsubscribedCountNum:0];
    
    NewFriendsViewController *addFriendsViewController = [[NewFriendsViewController alloc] init];
    [self.navigationController pushViewController:addFriendsViewController animated:YES];
}


#pragma mark 点击显示或创建群组
- (void)showOrCreateGroups
{
    NSLog(@"进入群组列表界面...");
    RoomsViewController *roomsViewController = [[RoomsViewController alloc] init];
    [self.navigationController pushViewController:roomsViewController animated:YES];
}

#pragma mark 搜索好友
- (void)searchFriends
{
    NSLog(@"联系人界面代理搜索联系人...");
    
}


/////////////////////////////////////////////////////////////
#pragma mark search delegate
/////////////////////////////////////////////////////////////



#pragma mark 点击搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索联系人...");
    searchBar.showsCancelButton = YES;
}

#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"点击取消按钮");
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

////////////////////////////////////////////////////////////////////////////
#pragma mark - UserGroup Delegate
////////////////////////////////////////////////////////////////////////////

#pragma mark 点击展开分组
- (void)clickUserGroup:(UIButton *)sender
{
    NSString *string = [NSString stringWithFormat:@"%d", sender.tag - 100];
    if ([selectedArr containsObject:string])
    {
        [selectedArr removeObject:string];
    }
    else
    {
        [selectedArr addObject:string];
    }
    [self.tableView reloadData];
}


/////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
/////////////////////////////////////////////////////////////////////////////

#pragma mark 用户分组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.contactsViewModel numberOfSections];
}


#pragma mark 用户分组
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *string = [NSString stringWithFormat:@"%ld", (long)section];
    
    static NSString *userGroupCellIdentifier = @"userGroupCell";
    id object = [self.contactsViewModel objectAtSection:section];
    UserGroupCell *userGroupCell = [tableView dequeueReusableCellWithIdentifier:userGroupCellIdentifier];
    if (!userGroupCell) {
        userGroupCell = [[UserGroupCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:userGroupCellIdentifier];
    }
    
    if ([selectedArr containsObject:string]) {
        [userGroupCell.bgButton setImage:[UIImage imageNamed:@"indicator_expanded"] forState:UIControlStateNormal];
    }
    else {
        [userGroupCell.bgButton setImage:[UIImage imageNamed:@"indicator_unexpanded"] forState:UIControlStateNormal];
    }
    
    userGroupCell.delegate = self;
    userGroupCell.bgButton.tag = 100 + section;
    
    [(UserGroupCell *)userGroupCell shouldUpdateCellWithObject:object];
    return userGroupCell;
}

#pragma mark 每个分组用户数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *string = [NSString stringWithFormat:@"%ld", (long)section];
    if ([selectedArr containsObject:string]) {
        return [self.contactsViewModel numberOfItemsInSection:section];
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *indexStr = [NSString stringWithFormat:@"%ld", (long)indexPath.section];
    
    static NSString *UserListCellIdentifier = @"UserListCell";
    
    id object = [self.contactsViewModel objectAtIndexPath:indexPath];
    UserListCell *userListCell = [tableView dequeueReusableCellWithIdentifier:UserListCellIdentifier];
    
    if (!userListCell) {
        userListCell = [[UserListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:UserListCellIdentifier];
    }
    if ([selectedArr containsObject:indexStr]) {
        [(UserListCell *)userListCell shouldUpdateCellWithObject:object];
    }
    return userListCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *user = [self.contactsViewModel objectAtIndexPath:indexPath];
    ChatViewController *chatViewController = [[ChatViewController alloc] initWithBuddyJID:user.jid buddyName:user.displayName];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

#pragma mark 用户行高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

#pragma mark 用户分组高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1f;
}


@end
