//
//  UserCategoryCell.m
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "UserGroupCell.h"
#import "XMPPManager.h"
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import <XMPPUserCoreDataStorageObject.h>


typedef void (^ContactCompleteBlock)(BOOL complete);

@interface UserGroupCell()<XMPPStreamDelegate>

@property (nonatomic, strong) UIImageView *bottomLine;

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *contact;


@end


@implementation UserGroupCell

#pragma mark 初始化风格
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.bgButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
        [self.bgButton setImage:[UIImage imageNamed:@"indicator_unexpanded"] forState:UIControlStateNormal];
        [self.bgButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.bgButton.imageView.contentMode = UIViewContentModeCenter;
        self.bgButton.imageView.clipsToBounds = NO;
        self.bgButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.bgButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        self.bgButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        [self.bgButton addTarget:self action:@selector(groupBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.bgButton];
        
        // 当前在线好友数
        self.onlineCountSum = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, self.frame.size.height)];
        self.onlineCountSum.font = [UIFont systemFontOfSize:14.f];
        self.onlineCountSum.textColor = [UIColor grayColor];
        self.onlineCountSum.highlightedTextColor = self.textLabel.textColor;
        self.onlineCountSum.centerX = self.centerX;
        self.onlineCountSum.right = self.width - 5;
        self.onlineCountSum.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.onlineCountSum];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 39, [UIScreen mainScreen].bounds.size.width, 1)];
        [self.bottomLine setImage:[UIImage imageNamed:@"splitLine"]];
        [self addSubview:self.bottomLine];
    }
    return self;
}

#pragma mark 设置组名称、在线好友数
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        
        [self.bgButton setTitle:[object allKeys][0] forState:UIControlStateNormal];
        NSInteger count = 0, sum = 0;
        NSArray *userArray = [object valueForKey:[object allKeys][0]];
        sum = userArray.count;
        
        for (XMPPUserCoreDataStorageObject *user in userArray) {
            self.contact = user;
            if (self.contact.section == 0) {
                count++;
            }
        }
        self.onlineCountSum.text = [NSString stringWithFormat:@"%ld/%ld", (long)count, (long)sum];
    }
    return YES;
}


#pragma mark 点击分组
- (void)groupBtnClick:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickUserGroup:)]) {
        [self.delegate clickUserGroup:sender];
    }
}



@end
