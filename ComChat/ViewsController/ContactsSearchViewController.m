//
//  AddFriendOrGroupViewController.m
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ContactsSearchViewController.h"
#import "XMPPManager.h"
#import "Macros.h"
#import "UIViewAdditions.h"
#import <MBProgressHUD.h>
#import "UserListCell.h"
#import <ReactiveCocoa.h>
#import "UserDetailViewController.h"
#import "UIView+Toast.h"
#import "XMPP+IM.h"


@interface ContactsSearchViewController () {
    MBProgressHUD *HUD;
}

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation ContactsSearchViewController


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
                                                     name:@"SEARCH_CONTACTS_RELOAD_DATA"
                                                   object:nil];
    }
    return self;
}


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [self.searchBar setPlaceholder:@"搜索联系人"];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"搜索联系人";

    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView reloadData];
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
    [super viewWillAppear:animated];
}



#pragma mark 接收到刷新tableView通知
- (void)reloadDataNofity
{
    [self.tableView reloadData];
}





/////////////////////////////////////////////////////////////////////
#pragma mark Search Bar Delegate
/////////////////////////////////////////////////////////////////////

#pragma mark 输入搜索内容
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"正在输入搜索内容...");
    searchBar.showsCancelButton = YES;
}



#pragma mark 点击搜索按钮
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索...");
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    HUD.delegate = self;
    HUD.labelText = @"搜索联系人...";
    [HUD show:YES];
    
    NSString *searchTerm = [searchBar text];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.contactsViewModel searchContacts:searchTerm];
    [self.tableView reloadData];
}


#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.tableView reloadData];
}



#pragma mark 搜索框内容变化
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}





/////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
/////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contactsViewModel numberOfSearchItemsInSection:section];
}


#pragma mark 设置Cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"RecentContactCell";
    UserListCell *userListcell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!userListcell) {
        userListcell = [[UserListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSString *userJid = [self.contactsViewModel objectAtSearchIndexPath:indexPath];
    [userListcell shouldUpdateCellWithSearchObject:userJid];
    
    return userListcell;
}

#pragma mark 设置Cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *userName = [self.contactsViewModel objectAtSearchIndexPath:indexPath];
    UserDetailViewController *userDetailViewController = [[UserDetailViewController alloc] initWithUser:userName];
    [self.navigationController pushViewController:userDetailViewController animated:YES];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"ContactsViewModel接收到IQ包%@", iq);
    
    if ([iq isSearchContacts]) {
        [HUD hide:YES];
        
        if (![self.contactsViewModel numberOfSearchItemsInSection:0]) {
            [self.view makeToast:@"不存在该联系人" duration:1.0 position:CSToastPositionTop];
        }
    }
    return YES;
}



@end
