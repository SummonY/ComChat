//
//  RoomsListCell.m
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RoomsListCell.h"
#import "UIViewAdditions.h"
#import "XMPPManager.h"
#import <XMPPGroupCoreDataStorageObject.h>

@interface RoomsListCell()<XMPPStreamDelegate>

@property (nonatomic, strong) UIImageView *groupImage;
@property (nonatomic, strong) UILabel *groupName;
@property (nonatomic, strong) UIImageView *bottomLine;

@property (nonatomic, strong) XMPPGroupCoreDataStorageObject *group;

@end



@implementation RoomsListCell


#pragma mark 初始化Cell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 群组头像
        self.groupImage = [[UIImageView alloc] initWithFrame:CGRectMake(5.f, 5.f, 37, 37)];
        self.groupImage.image = [UIImage imageNamed:@"group_head_default"];
        self.groupImage.layer.cornerRadius = 3.f;
        self.groupImage.clipsToBounds = YES;
        self.groupImage.centerY = self.centerY;
        [self.contentView addSubview:self.groupImage];
        
        // 群组名称
        self.groupName = [[UILabel alloc] initWithFrame:CGRectMake(0, 3, 300, 20)];
        self.groupName.font = [UIFont boldSystemFontOfSize:14.f];
        self.groupName.textColor = [UIColor blackColor];
        self.groupName.highlightedTextColor = self.textLabel.textColor;
        self.groupName.left = self.groupImage.right + 5;
        self.groupName.centerY = self.centerY;
        [self.contentView addSubview:self.groupName];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, [UIScreen mainScreen].bounds.size.width, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}


- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[XMPPGroupCoreDataStorageObject class]]) {
        XMPPGroupCoreDataStorageObject *grp = (XMPPGroupCoreDataStorageObject *)object;
        self.group = grp;
        /*
        // 设置群组头像
        if (!self.group.photo) {
            self.headImage.image = [UIImage imageNamed:@"user_head_default"];
        } else {
            self.headImage.image = self.contact.photo;
        }
        */
        
        // 设置群组名称
        self.groupName.text = self.group.name;
        
    }
    return YES;
}


- (BOOL)shouldUpdateCellWithRoomsObject:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        NSString *grp = (NSString *)object;
        
        /*
         // 设置群组头像
         if (!self.group.photo) {
         self.headImage.image = [UIImage imageNamed:@"user_head_default"];
         } else {
         self.headImage.image = self.contact.photo;
         }
         */
        
        // 设置群组名称
        self.groupName.text = [self getRoomName:grp];
        
    }
    return YES;
}


- (NSString *)getRoomName:(NSString *)roomJID
{
    NSString *roomName = [NSString stringWithFormat:@"%@", [roomJID componentsSeparatedByString:@"@"][0]];
    return roomName;
}



#pragma mark 更新搜索到的Cell
- (BOOL)shouldUpdateCellWithSearchObject:(id)object
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *roomDic = object;
        // 设置群组名称
        self.groupName.text = [roomDic allValues][0];
        
    }
    return YES;
}



///////////////////////////////////////////////////////////////
#pragma mark XMPP Stream delegate
///////////////////////////////////////////////////////////////

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"接收到IQ信息包，设置群组头像等信息.");
    
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error
{
    NSLog(@"群组列表接收到错误, %@", error);
    
}


@end
