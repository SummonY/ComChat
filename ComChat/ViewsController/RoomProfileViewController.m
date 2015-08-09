//
//  RoomProfileViewController.m
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomProfileViewController.h"
#import "XMPPManager.h"
#import <MBProgressHUD.h>
#import "UIView+Toast.h"
#import "RoomMembersListViewController.h"


@interface RoomProfileViewController () {
    
    MBProgressHUD* HUD;
}

@property (nonatomic, strong) XMPPJID *roomJID;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *roomSubject;
@property (nonatomic, strong) NSString *roomOccupants;
@property (nonatomic, strong) NSString *roomCreationDate;

@property (nonatomic, assign) BOOL isJoinedGroup;
@property (nonatomic, assign) BOOL isRoomOwner;


@end


@implementation RoomProfileViewController


- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}


#pragma mark 初始化群组
- (void)initWithRoomJID:(XMPPJID *)roomJID
{
    self.roomsViewModel = [RoomsViewModel sharedViewModel];
    
    self.roomJID = roomJID;
    self.isJoinedGroup = [self judgeIsInRoom];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(roomInfoReloadDataNotify:)
                                                 name:@"ROOM_INFO_RELOAD_DATA"
                                               object:nil];
}


#pragma mark 判断自己是否在该群组
- (BOOL)judgeIsInRoom
{
    return [self.roomsViewModel isExistedInRoomJid:self.roomJID.full];
}

#pragma mark 判断自己是否为房间拥有者
- (BOOL)judgeIsOwner
{
    return [self.roomsViewModel isRoomOwner:[XMPPManager sharedManager].myJID.bare];
}



- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    self.navigationItem.title = @"群组资料";
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // 获取房间成员列表
    [self.roomsViewModel fetchRoomMembersList:self.roomJID.full];
    
    // 获取房间信息
    [self.roomsViewModel fetchRoomsInfo:self.roomJID.full];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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


#pragma mark 刷新数据
- (void)roomInfoReloadDataNotify:(NSNotification *)notify
{
    NSDictionary *roomInfoDic = [notify userInfo];
    
    self.roomName = [roomInfoDic objectForKey:@"roomName"];
    self.roomSubject = [roomInfoDic objectForKey:@"subject"];
    self.roomOccupants = [roomInfoDic objectForKey:@"occupants"];
    self.roomCreationDate = [roomInfoDic objectForKey:@"creationdate"];
    
    self.isJoinedGroup = [self judgeIsInRoom];
    self.isRoomOwner = [self judgeIsOwner];
    [self.tableView reloadData];
}



///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
///////////////////////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* reuseIdentifier  = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    }
    
    switch (indexPath.section) {
        case 0:
        {
            cell.imageView.image = [UIImage imageNamed:@"group_head_default"];
            cell.textLabel.text = self.roomName;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        case 1:
        {
            cell.textLabel.text = @"创建日期";
            cell.detailTextLabel.text = self.roomCreationDate;
            break;
        }
        case 2:
        {
            cell.textLabel.text = @"主题";
            cell.detailTextLabel.text = self.roomSubject;
            break;
            
        }
        case 3:
        {
            self.isJoinedGroup = [self judgeIsInRoom];
            if (self.isJoinedGroup) {
                cell.textLabel.text = @"群组成员";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@/%ld", self.roomOccupants, (long)[self.roomsViewModel totalNumbersOfRoomAffiliation]];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                cell.textLabel.text = @"群组在线成员个数";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", self.roomOccupants];
            }
            break;
        }
        case 4:
        {
            self.isJoinedGroup = [self judgeIsInRoom];
            if (self.isJoinedGroup) {
                cell.backgroundColor = [UIColor redColor];
                if (self.isRoomOwner) {
                    cell.textLabel.text = @"解散该群";
                } else {
                    cell.textLabel.text = @"退出此群";
                }
            } else {
                cell.textLabel.text = @"加入此群";
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        default:
            break;
    }
    
    return cell;
}



#pragma mark 设置选中Cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        RoomMembersListViewController *roomMembersListViewController = [[RoomMembersListViewController alloc] initWithRoomJid:self.roomJID.full];
        [self.navigationController pushViewController:roomMembersListViewController animated:YES];
    } else if (indexPath.section == 4) {
        
        self.isJoinedGroup = [self judgeIsInRoom];
        if (self.isJoinedGroup) {
            
            self.isRoomOwner = [self judgeIsOwner];
            if (self.isRoomOwner) {
                // 解散该群
                [self.roomsViewModel destoryRoomWithRoomJID:self.roomJID.full];
            } else {
                //退出此群
                [self.roomsViewModel leaveRoomWithRoomJID:self.roomJID.full];
            }
            
        } else {
            //加入此群
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            HUD.delegate = self;
            HUD.labelText = @"正在申请加入...";
            [HUD show:YES];
            
            [self.roomsViewModel registerRoomWithRoomJID:self.roomJID.full];        // 注册加入群组
            //[self.roomsViewModel joinRoomWithRoomJID:self.roomJID.full];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10.0f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 90;
    }
    else
        return 40;
}



///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRoomDelegate
///////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"RoomProfileViewController已经加入群组");
    [HUD hide:YES];
    [self.view makeToast:@"加入群组成功" duration:1.0 position:CSToastPositionTop];
}




@end
