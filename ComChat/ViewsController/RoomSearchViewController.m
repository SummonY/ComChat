//
//  RoomSearchViewController.m
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomSearchViewController.h"
#import "UIViewAdditions.h"
#import "RoomsListCell.h"
#import "RoomProfileViewController.h"
#import <ReactiveCocoa.h>
#import <MBProgressHUD.h>
#import "XMPP+IM.h"



@interface RoomSearchViewController ()<UISearchBarDelegate> {
    UIScrollView *mainScroll;

    MBProgressHUD* HUD;
}

@property (nonatomic, strong) UISearchBar *searchBar;


@end

@implementation RoomSearchViewController


#pragma mark 初始化界面
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.roomsViewModel = [RoomsViewModel sharedViewModel];
    
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        @weakify(self)
        [self.roomsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDataNofity)
                                                     name:@"SEARCH_GROUP_RELOAD_DATA"
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
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [self.searchBar setPlaceholder:@"搜索群组"];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"查找群组";
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
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
    NSLog(@"开始搜索");
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    HUD.delegate = self;
    HUD.labelText = @"正在搜索群组...";
    [HUD show:YES];
    
    NSString *searchTerm = [searchBar text];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.roomsViewModel searchRooms:searchTerm];
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
    return [self.roomsViewModel numberOfSearchItemsInSection:section];
}


#pragma mark 设置Cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"RecentContactCell";
    RoomsListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[RoomsListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary *roomDic = [self.roomsViewModel objectAtSearchIndexPath:indexPath];
    [cell shouldUpdateCellWithSearchObject:roomDic];
    
    return cell;
}

#pragma mark 设置Cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *roomDic = [self.roomsViewModel objectAtSearchIndexPath:indexPath];
    XMPPJID *roomJid = [XMPPJID jidWithString:[roomDic allKeys][0]];
    RoomProfileViewController *roomProfileViewController = [[RoomProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [roomProfileViewController initWithRoomJID:roomJid];
    [self.navigationController pushViewController:roomProfileViewController animated:YES];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"RoomSearchViewController 接收到IQ包");
    if ([iq isChatRoomItems]) {
        [HUD hide:YES];
    }
    
    return YES;
}



@end
