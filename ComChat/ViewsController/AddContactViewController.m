//
//  AddContactViewController.m
//  ComChat
//
//  Created by D404 on 15/7/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "AddContactViewController.h"
#import "XMPPManager.h"
#import "Macros.h"
#import "UIViewAdditions.h"
#import "UIView+Toast.h"
#import <MBProgressHUD.h>


@interface AddContactViewController () {
    MBProgressHUD *HUD;
}

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userJID;
@property (nonatomic, strong) NSString *userNickName;
@property (nonatomic, strong) NSString *userGroup;

@property (nonatomic, strong) UITextField *nickNameField;
@property (nonatomic, strong) UITextField *userGroupField;

@end

@implementation AddContactViewController


#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoster removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark 初始化用户详细信息
- (void)initWithUser:(NSString *)userName
{
    self.userName = userName;
    self.userJID = [NSString stringWithFormat:@"%@@%@", self.userName, XMPP_DOMAIN];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"添加好友";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStyleDone target:self action:@selector(addContact)] animated:YES];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark 添加好友
- (void)addContact
{
    NSLog(@"点击添加好友...");
    
    XMPPJID *userJID = [XMPPJID jidWithString:self.userJID];
    
    if ([self.nickNameField.text isEqualToString:@""]) {
        self.userNickName = self.userName;
    }
    else {
        self.userNickName = self.nickNameField.text;
    }
    
    if ([self.userGroupField.text isEqualToString:@""]) {
        self.userGroup = @"我的好友";
    } else {
        self.userGroup = self.userGroupField.text;
    }
    NSArray *userGroupArray = [NSArray arrayWithObject:self.userGroup];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.delegate = self;
    HUD.labelText = @"正在登录...";
    [HUD show:YES];
    
    [[XMPPManager sharedManager].xmppRoster addUser:userJID withNickname:self.userNickName groups:userGroupArray subscribeToPresence:YES];
    
}




////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* reuseIdentifier  = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.textLabel.centerY = cell.centerY;
    }
    
    switch (indexPath.section) {
        case 0:
        {
            self.nickNameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 45)];
            [self.nickNameField setPlaceholder:@"备注用户名称"];
            self.nickNameField.backgroundColor = [UIColor whiteColor];
            [self.nickNameField setFont:[UIFont systemFontOfSize:14]];
            self.nickNameField.clearButtonMode = UITextFieldViewModeAlways;
            self.nickNameField.delegate = self;
            
            [cell addSubview:self.nickNameField];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        case 1:
        {
            /* 设置群组输入框 */
            self.userGroupField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 45)];
            [self.userGroupField setPlaceholder:@"设置用户分组"];
            self.userGroupField.backgroundColor = [UIColor whiteColor];
            [self.userGroupField setFont:[UIFont systemFontOfSize:14]];
            self.userGroupField.clearButtonMode = UITextFieldViewModeAlways;
            self.userGroupField.delegate = self;
            
            [cell addSubview:self.userGroupField];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        default:
            break;
    }
    
    return cell;
}



- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.0f;
}


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    NSLog(@"AddContactViewController接收到Roster Item:%@", item);
    
    NSXMLElement *copyItem = [item copy];
    NSString *ask = [copyItem attributeStringValueForName:@"ask"];
    
    if ([ask isEqualToString:@"subscribe"]) {
        [HUD setHidden:YES];
        [self.view makeToast:@"已发送好友邀请" duration:0.5 position:CSToastPositionTop];
        
        int index = [[self.navigationController viewControllers] indexOfObject:self];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index - 2] animated:YES];
    }
}




@end
