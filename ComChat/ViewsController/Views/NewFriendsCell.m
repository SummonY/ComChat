//
//  NewFriendsCell.m
//  ComChat
//
//  Created by D404 on 15/6/13.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewFriendsCell.h"
#import "UIViewAdditions.h"
#import <XMPPUserCoreDataStorageObject.h>

@interface NewFriendsCell()

@property (nonatomic, strong) NSString *userJID;
@property (nonatomic, strong) UIImageView *headImage;
@property (nonatomic, strong) UILabel *userName;
@property (nonatomic, strong) UILabel *agreeOrRejectSataus;
@property (nonatomic, strong) UIImageView *bottomLine;

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *contact;

@end


@implementation NewFriendsCell

#pragma mark 初始化样式
- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        // 设置用户头像
        self.headImage = [[UIImageView alloc] initWithFrame:CGRectMake(3, 0, 40, 40)];
        self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        [self.contentView addSubview:_headImage];
        self.headImage.layer.cornerRadius = 3.f;
        self.headImage.centerY = self.centerY;
        self.headImage.clipsToBounds = YES;
        
        // 联系人名称
        self.userName = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 200, 20)];
        self.userName.font = [UIFont boldSystemFontOfSize:14.f];
        self.userName.textColor = [UIColor blackColor];
        self.userName.highlightedTextColor = self.textLabel.textColor;
        [self.contentView addSubview:self.userName];
        self.userName.left = self.headImage.right + 3;
        
        
        UILabel *detailInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        detailInfo.font = [UIFont boldSystemFontOfSize:14.f];
        detailInfo.text = @"对方请求加您为好友";
        detailInfo.textColor = [UIColor lightGrayColor];
        detailInfo.highlightedTextColor = detailInfo.textColor;
        detailInfo.top = self.userName.bottom + 3;
        detailInfo.left = self.headImage.right + 3;
        [self.contentView addSubview:detailInfo];
        
        
        // 设置同意或拒绝状态
        self.agreeOrRejectSataus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 63, 21)];
        [self addSubview:self.agreeOrRejectSataus];
        [self.agreeOrRejectSataus setTextColor: [UIColor lightGrayColor]];
        self.agreeOrRejectSataus.right = self.width - 10;
        self.agreeOrRejectSataus.centerY = self.centerY;
        
        // 设置按钮视图
        UIView* btnView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
        
        // 设置同意按钮
        UIButton* agreeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 42, 20)];
        [agreeBtn setTitle:@"同意" forState:UIControlStateNormal];
        [agreeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [agreeBtn addTarget:self action:@selector(agreeAddFriend:) forControlEvents:UIControlEventTouchUpInside];
        
        
        // 设置拒绝按钮
        UIButton* rejectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 42, 20)];
        [rejectBtn setTitle:@"拒绝" forState:UIControlStateNormal];
        [rejectBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [rejectBtn addTarget:self action:@selector(rejectAddFriend:) forControlEvents:UIControlEventTouchUpInside];
        rejectBtn.left = agreeBtn.right + 3;
        
        [btnView addSubview:rejectBtn];
        [btnView addSubview:agreeBtn];
        btnView.right = self.width - 5;
        btnView.centerY = self.centerY;
        [self.contentView addSubview:btnView];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 49, [UIScreen mainScreen].bounds.size.width, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];

    }
    return self;
}


#pragma mark 拒绝添加好友
- (IBAction)rejectAddFriend:(UIButton *)sender {
    //[sender.superview removeFromSuperview];

    if (self.delegate && [self.delegate respondsToSelector:@selector(rejectAddFriend:)]) {
        [self.delegate rejectAddFriend:self.userJID];
    }
}

#pragma mark 同意添加好友
- (void)agreeAddFriend:(UIButton *)sender {
    //[sender.superview removeFromSuperview];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(agreeAddFriend:)]) {
        [self.delegate agreeAddFriend:self.userJID];
    }
}


#pragma mark 更新Cell
// TODO:获取用户完整信息，并显示头像等
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        NSString *contact = [NSString stringWithString:object];
        self.userJID = [NSString stringWithString:contact];
        self.userName.text = [self getUserName:contact];
    }
    return YES;
}

#pragma mark 获取用户名称
- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}


@end
