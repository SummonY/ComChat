//
//  GroupsViewController.m
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomsViewController.h"
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import "ChatViewController.h"
#import "GroupChatViewController.h"
#import "RoomsListCell.h"
#import "CreateRoomViewController.h"
#import "RoomSearchViewController.h"


@interface RoomsViewController ()

@end


@implementation RoomsViewController

#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.f)];
    [searchBar setPlaceholder:@"搜索"];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
}


#pragma mark 初始化界面
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.roomsViewModel = [RoomsViewModel sharedViewModel];
        
        @weakify(self)
        [self.roomsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDataNotify)
                                                     name:@"ROOMS_LIST_RELOAD_DATA"
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
    self.navigationItem.title = @"群组";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"create_group"] style:UIBarButtonItemStylePlain target:self action:@selector(createRooms:)] animated:YES];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchRoomsAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    //[self fetchRoomsAction];
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



#pragma mark 创建群组
- (IBAction)createRooms:(id)sender
{
    NSLog(@"创建群组...");
    CreateRoomViewController *createRoomViewController = [[CreateRoomViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:createRoomViewController animated:YES];
}


#pragma mark 刷新获取群组
- (void)fetchRoomsAction
{
    NSLog(@"刷新获取群组列表...");
    //[self.roomsViewModel fetchRoomsList];
    [self.roomsViewModel fetchRoomBookmarks];
    //[self.roomsViewModel fetchRoomsFromCoreData];
    [self.refreshControl endRefreshing];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark search delegate
////////////////////////////////////////////////////////////////////////////////


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



///////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
///////////////////////////////////////////////////////////////////////////////////////


#pragma mark 群组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark 返回群组数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return [self.roomsViewModel numberOfRoomsBookmarkedInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIndentifier = @"RoomsIndentifier";
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIndentifier];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier forIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:@"group_search"];
        cell.textLabel.text = @"添加群组";
        
        return cell;
    }
    else {
        static NSString *RoomListCellIdentifier = @"RoomListCell";
        
        id object = [self.roomsViewModel objectOfRoomsBookmarkedAtIndexPath:indexPath];
        RoomsListCell *roomsListCell = [tableView dequeueReusableCellWithIdentifier:RoomListCellIdentifier];
        
        if (!roomsListCell) {
            roomsListCell = [[RoomsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RoomListCellIdentifier];
        }
        
        [(RoomsListCell *)roomsListCell shouldUpdateCellWithRoomsObject:object];
        return roomsListCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSLog(@"点击查找群组...");
        RoomSearchViewController *roomSearchViewController = [[RoomSearchViewController alloc] init];
        [self.navigationController pushViewController:roomSearchViewController animated:YES];
    }
    else {
        NSString *roomJid = [self.roomsViewModel objectOfRoomsBookmarkedAtIndexPath:indexPath];
        NSLog(@"点击群组: %@", roomJid);
        
        XMPPJID *roomJID = [XMPPJID jidWithString:roomJid];
        GroupChatViewController *groupChatViewController = [[GroupChatViewController alloc] initWithGroupJID:roomJID groupName:[self getRoomName:roomJid]];
        [self.navigationController pushViewController:groupChatViewController animated:YES];
    }
}

- (NSString *)getRoomName:(NSString *)roomJID
{
    NSString *roomName = [NSString stringWithFormat:@"%@", [roomJID componentsSeparatedByString:@"@"][0]];
    return roomName;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}


@end
