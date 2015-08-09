//
//  InviteUserCell.m
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "InviteUserCell.h"
#import <XMPPUserCoreDataStorageObject.h>
#import "UIViewAdditions.h"


@interface InviteUserCell()

@property (nonatomic, strong) UIImageView*	checkImage;

@property (nonatomic, strong) UIImageView *headImage;
@property (nonatomic, strong) UILabel *userName;
@property (nonatomic, strong) UIImageView *bottomLine;

@end


@implementation InviteUserCell

#pragma mark 初始化Cell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 设置选中图标
        self.checkImage = [[UIImageView alloc] initWithFrame:CGRectMake(3, 3, 35, 35)];
        self.checkImage.image = [UIImage imageNamed:@"unselected_invite"];
        self.checkImage.centerY = self.centerY;
        [self.contentView addSubview:self.checkImage];
        
        // 用户头像
        self.headImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.f, 5.f, 37, 37)];
        self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        [self.contentView addSubview:_headImage];
        self.headImage.layer.cornerRadius = 3.f;
        self.headImage.clipsToBounds = YES;
        self.headImage.centerY = self.centerY;
        self.headImage.left = self.checkImage.right + 5;
        
        // 用户名称
        self.userName = [[UILabel alloc] initWithFrame:CGRectMake(50, 2, 200, 20)];
        self.userName.font = [UIFont boldSystemFontOfSize:14.f];
        self.userName.textColor = [UIColor blackColor];
        self.userName.highlightedTextColor = self.textLabel.textColor;
        self.userName.centerY = self.centerY;
        self.userName.left = self.headImage.right + 5;
        [self.contentView addSubview:self.userName];

        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 49, self.width, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}


#pragma mark 设置选中
- (void) setChecked:(BOOL)isChecked
{
    if (isChecked) {
        self.checkImage.image = [UIImage imageNamed:@"selected_invite"];
        self.backgroundView.backgroundColor = [UIColor colorWithRed:223.0f / 255.0f green:230.f / 255.0f blue:250.f / 255.0f alpha:1.0];
    } else {
        self.checkImage.image = [UIImage imageNamed:@"unselected_invite"];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
    }
    self.isChecked = isChecked;
}

#pragma mark 设置用户头像、名称、是否在线
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[XMPPUserCoreDataStorageObject class]]) {
        XMPPUserCoreDataStorageObject *user = (XMPPUserCoreDataStorageObject *)object;
        // 设置用户头像
        if (!user.photo) {
            self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        } else {
            self.headImage.image = user.photo;
        }
        
        // 设置用户名称
        self.userName.text = user.displayName;
    }
    return YES;
}




@end
