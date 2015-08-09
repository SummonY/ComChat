//
//  InviteUserViewController.m
//  ComChat
//
//  Created by D404 on 15/6/29.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "InviteUserViewController.h"
#import "InviteUserCell.h"
#import "UIViewAdditions.h"


#define BOTTOM_VIEW_HEIGHT      40.0f


@interface InviteUserViewController ()<UITableViewDataSource, UITableViewDelegate> {
    UISearchDisplayController *searchDisplayController;
}

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *checkedContacts;
@property (nonatomic, strong) NSString *roomJID;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *selectedDes;
@property (nonatomic, strong) UILabel *selectedNum;
@property (nonatomic, strong) UIButton *bottomBtn;

@end

@implementation InviteUserViewController

/*
#pragma mark 初始化风格
- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        self.contactsViewModel = [ContactsViewModel sharedViewModel];
        self.roomsViewModel = [RoomsViewModel sharedViewModel];
        
        self.checkedContacts = [[NSMutableArray alloc] init];
        
    }
    return self;
}
*/

#pragma mark 初始化视图
- (void)loadView
{
    [super loadView];
    
    // 初始化tableview
    CGFloat tableViewHeight = [UIScreen mainScreen].bounds.size.height - BOTTOM_VIEW_HEIGHT;        // tableView 高度
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, tableViewHeight) style:UITableViewStyleGrouped];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
    
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, screenSize.height - BOTTOM_VIEW_HEIGHT, screenSize.width, BOTTOM_VIEW_HEIGHT)];
    self.bottomView.backgroundColor = [UIColor lightTextColor];
    [self.view addSubview:self.bottomView];
    
    self.selectedDes = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, 120, 20)];
    self.selectedDes.text = @"邀请好友个数:";
    [self.bottomView addSubview:self.selectedDes];
    
    self.selectedNum = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, 30, 20)];
    self.selectedNum.text = @"0";
    self.selectedNum.left = self.selectedDes.right + 10;
    [self.bottomView addSubview:self.selectedNum];
    
    self.bottomBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, 80, 30)];
    [self.bottomBtn setTitle:@"确认邀请" forState:UIControlStateNormal];
    self.bottomBtn.backgroundColor = [UIColor grayColor];
    [self.bottomBtn addTarget:self action:@selector(confirmInvite) forControlEvents:UIControlEventTouchUpInside];
    self.bottomBtn.enabled = NO;
    self.bottomBtn.right = self.view.right - 5;
    [self.bottomView addSubview:self.bottomBtn];

}

#pragma mark 初始化房间id
- (void)initWithRoom:(NSString *)roomJid
{
    self.roomJID = [NSString stringWithString:roomJid];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"邀请好友";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(cancleSelected)] animated:YES];

    self.view.backgroundColor = [UIColor whiteColor];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // 添加搜索条
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
    searchBar.placeholder = @"搜索";
    
    self.tableView.tableHeaderView = searchBar;
    
    
    self.contactsViewModel = [ContactsViewModel sharedViewModel];
    self.roomsViewModel = [RoomsViewModel sharedViewModel];
    
    self.checkedContacts = [[NSMutableArray alloc] init];
    
    // 搜索控制器
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark 取消邀请好友
- (void)cancleSelected
{
    NSLog(@"取消邀请好友...");
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark 确认邀请加入群组
- (void)confirmInvite
{
    NSLog(@"确认邀请好友：%@", self.checkedContacts);
    
    for (NSString *userJid in self.checkedContacts) {
        [self.roomsViewModel inviteUser:userJid inRoom:self.roomJID];
    }
}




//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
//////////////////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contactsViewModel numberOfInviteUsersInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *inviteUserCellIdentifier = @"inviteUserCell";
    InviteUserCell *inviteUserCell = [tableView dequeueReusableCellWithIdentifier:inviteUserCellIdentifier];
    
    if (!inviteUserCell) {
        inviteUserCell = [[InviteUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:inviteUserCellIdentifier];
    }
    
    id object = [self.contactsViewModel objectAtInviteUsersIndexPath:indexPath];
    [(InviteUserCell *)inviteUserCell shouldUpdateCellWithObject:object];
    
    return inviteUserCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *user = [self.contactsViewModel objectAtIndexPath:indexPath];
    InviteUserCell *inviteUserCell = (InviteUserCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    [inviteUserCell setChecked:!inviteUserCell.isChecked];
    if (inviteUserCell.isChecked) {
        [self.checkedContacts addObject:user.jidStr];
    } else {
        [self.checkedContacts removeObject:user.jidStr];
    }
    
    if (self.checkedContacts.count == 0) {
        self.selectedNum.text = @"0";
        self.bottomBtn.enabled = NO;
    } else {
        self.selectedNum.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.checkedContacts.count];
        self.bottomBtn.enabled = YES;
        self.bottomBtn.backgroundColor = [UIColor cyanColor];
    }
}


- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}



@end
