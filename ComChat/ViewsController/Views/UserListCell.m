//
//  UserListCell.m
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "UserListCell.h"
#import "XMPPManager.h"

typedef void (^ContactCompleteBlock)(BOOL complete);

@interface UserListCell()<XMPPStreamDelegate>

@property (nonatomic, strong) UIImageView *headImage;
@property (nonatomic, strong) UILabel *userName;
@property (nonatomic, strong) UILabel *userStatus;
@property (nonatomic, strong) UIImageView *bottomLine;

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *contact;
@property (nonatomic, strong) ContactCompleteBlock completeBlock;

@end


@implementation UserListCell


#pragma mark 初始化Cell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 用户头像
        self.headImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.f, 5.f, 37, 37)];
        self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        [self.contentView addSubview:_headImage];
        self.headImage.layer.cornerRadius = 3.f;
        self.headImage.clipsToBounds = YES;
        
        // 用户名称
        self.userName = [[UILabel alloc] initWithFrame:CGRectMake(50, 2, 200, 20)];
        self.userName.font = [UIFont boldSystemFontOfSize:14.f];
        self.userName.textColor = [UIColor blackColor];
        self.userName.highlightedTextColor = self.textLabel.textColor;
        [self.contentView addSubview:self.userName];
       
        // 用户是否在线
        self.userStatus = [[UILabel alloc] initWithFrame:CGRectMake(50, 30, 200, 15)];
        self.userStatus.font = [UIFont systemFontOfSize:12.f];
        self.userStatus.textColor = [UIColor grayColor];
        self.userStatus.highlightedTextColor = self.detailTextLabel.textColor;
        [self.contentView addSubview:self.userStatus];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(50, 48, [UIScreen mainScreen].bounds.size.width - 50, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}


#pragma mark 设置用户头像、名称、是否在线
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[XMPPUserCoreDataStorageObject class]]) {
        XMPPUserCoreDataStorageObject *user = (XMPPUserCoreDataStorageObject *)object;
        self.contact = user;
        // 设置用户头像
        if (!self.contact.photo) {
            self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        } else {
            self.headImage.image = self.contact.photo;
        }
        
        // 设置用户名称
        self.userName.text = self.contact.displayName;
        
        // 设置用户是否在线
        if (self.contact.section == 0) {
            self.userStatus.text = @"[在线]";
        } else if (self.contact.section == 1) {
            self.userStatus.text = @"[离开]";
        } else {
            self.userStatus.text = @"[离线请留言]";
        }
    }
    return YES;
}


- (BOOL)shouldUpdateCellWithSearchObject:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        NSString *userJid = (NSString *)object;
        //XMPPJID *userJID = [XMPPJID jidWithString:userJid];
        //[[XMPPManager sharedManager].xmppvCardTempModule fetchvCardTempForJID:userJID ignoreStorage:YES];
        
        /*
        // 设置用户头像
        if (!self.contact.photo) {
            self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        } else {
            self.headImage.image = self.contact.photo;
        }
        */
        self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        // 设置用户名称
        self.userName.text = userJid;
    }
    return YES;
}


#pragma mark 设置用户头像、名称、是否在线
- (BOOL)shouldUpdateCellWithRoomMembersObject:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        NSString *user = (NSString *)object;
        
        // 设置用户头像
        self.headImage.image = [UIImage imageNamed:@"user_head_default"];       // TODO：设置用户头像
        
        // 设置用户名称
        self.userName.text = [NSString stringWithFormat:@"%@", [self getUserName:user]];
    }
    return YES;
}

#pragma mark 根据用户JID获取用户名
- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}



///////////////////////////////////////////////////////////////
#pragma mark XMPP Stream delegate
///////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"接收到IQ信息包，设置用户头像等信息.");
    if ([self.contact.jid isEqualToJID:iq.from]) {
        if (self.contact.photo) {
            self.headImage.image = self.contact.photo;
        }
        else {
            self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        }
        if (self.completeBlock) {
            self.completeBlock(YES);
        }
        return YES;
    }
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error
{
    NSLog(@"用户列表接收到错误, %@", error);
    if (self.completeBlock) {
        self.completeBlock(NO);
    }
}


@end
