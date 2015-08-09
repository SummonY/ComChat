//
//  NewFriendsViewController.m
//  ComChat
//
//  Created by D404 on 15/6/13.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewFriendsViewController.h"
#import <ReactiveCocoa.h>
#import "ContactsSearchViewController.h"
#import "NewFriendsCell.h"
#import "UIViewAdditions.h"
#import "FriendManageViewController.h"


@interface NewFriendsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NewFriendsCell *addFriendsCell;

@end

@implementation NewFriendsViewController


- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [searchBar setPlaceholder:@"搜索"];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
}


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark 初始化界面
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.contactsViewModel = [ContactsViewModel sharedViewModel];
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
        @weakify(self)
        [self.contactsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDataNofity)
                                                     name:@"FRIENDS_INVITE_RELOAD_DATA"
                                                   object:nil];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* 设置导航条 */
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"新的好友";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_friend_nor"] style:UIBarButtonItemStylePlain target:self action:@selector(addFriends:)] animated:YES];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchContactsAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setHidesBottomBarWhenPushed:NO];
    [super viewWillDisappear:animated];
}


- (void)reloadDataNofity
{
    [self.tableView reloadData];
}



#pragma mark 点击添加好友
- (IBAction)addFriends:(id)sender
{
    NSLog(@"点击添加好友...");
    ContactsSearchViewController* contactsSearchViewController = [[ContactsSearchViewController alloc] init];
    [self.navigationController pushViewController:contactsSearchViewController animated:YES];
}


#pragma mark 刷新获取当前联系人状态
- (void)fetchContactsAction
{
    NSLog(@"刷新获取好友邀请...");
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}


#pragma mark 同意添加好友
- (void)agreeAddFriend:(NSString *)userJID {
    NSLog(@"同意添加好友");
    XMPPJID *userJid = [XMPPJID jidWithString:userJID];
    
    
    FriendManageViewController *friendManageViewController = [[FriendManageViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [friendManageViewController initWithUser:userJid.full];
    [self.navigationController pushViewController:friendManageViewController animated:YES];
    
    /*
    NSString *userNickName = [self getUserName:userJID];
    [[[XMPPManager sharedManager] xmppRoster] acceptPresenceSubscriptionRequestFrom:userJid andAddToRoster:YES];
    NSArray *userGroup = [NSArray arrayWithObject:@"我的好友"];
    [[XMPPManager sharedManager].xmppRoster addUser:userJid withNickname:userNickName groups:userGroup subscribeToPresence:YES];
     */
}


- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}


#pragma mark 拒绝添加好友
- (void)rejectAddFriend:(NSString *)userJID {
    NSLog(@"拒绝添加好友");
    XMPPJID *userJid = [XMPPJID jidWithString:userJID];
    [[[XMPPManager sharedManager] xmppRoster] rejectPresenceSubscriptionRequestFrom:userJid];
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



//////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
//////////////////////////////////////////////////////////////////////


#pragma mark 返回分组个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


#pragma mark 返回分组中成员个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contactsViewModel numberOfNewItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *newFriendsCellIdentifier = @"UserListCell";
    
    id object = [self.contactsViewModel objectAtNewIndexPath:indexPath];
    NewFriendsCell *newFriendsCell = [tableView dequeueReusableCellWithIdentifier:newFriendsCellIdentifier];
    
    if (!newFriendsCell) {
        newFriendsCell = [[NewFriendsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newFriendsCellIdentifier];
    }
    newFriendsCell.delegate = self;
    [(NewFriendsCell *)newFriendsCell shouldUpdateCellWithObject:object];
    return newFriendsCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}





@end
