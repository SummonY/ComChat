//
//  RecentRoomsCell.m
//  ComChat
//
//  Created by D404 on 15/7/10.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RecentRoomsCell.h"
#import <JSCustomBadge.h>
#import "UIViewAdditions.h"
#import "XMPPManager.h"
#import "ChatMessageEntityFactory.h"
#import "NSDate+IM.h"
#import "XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.h"


@interface RecentRoomsCell() {
    
}

@property (nonatomic, strong) UIImageView *headImage;
@property (nonatomic, strong) UILabel *roomName;
@property (nonatomic, strong) UILabel *roomMessage;
@property (nonatomic, strong) UIImageView *bottomLine;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) JSCustomBadge *badgeView;

@property (nonatomic, strong) XMPPRoomOccupantCoreDataStorageObject *roomOccupant;

@end


@implementation RecentRoomsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 头像
        self.headImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        self.headImage.image = [UIImage imageNamed:@"group_head_default"];
        [self.contentView addSubview:_headImage];
        self.headImage.layer.cornerRadius = 3.f;
        self.headImage.clipsToBounds = YES;
        
        // 联系人名称
        self.roomName = [[UILabel alloc] init];
        self.roomName.font = [UIFont boldSystemFontOfSize:14.f];
        self.roomName.textColor = [UIColor blackColor];
        self.roomName.highlightedTextColor = self.textLabel.textColor;
        [self.contentView addSubview:self.roomName];
        
        // 用户最新一条消息
        self.roomMessage = [[UILabel alloc] init];
        self.roomMessage.font = [UIFont systemFontOfSize:12.f];
        self.roomMessage.textColor = [UIColor grayColor];
        self.roomMessage.highlightedTextColor = self.roomMessage.textColor;
        [self.contentView addSubview:self.roomMessage];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 59, [UIScreen mainScreen].bounds.size.width, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
        
        // 日期
        _dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _dateLabel.font = [UIFont systemFontOfSize:13.f];
        _dateLabel.textColor = [UIColor grayColor];
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.highlightedTextColor = _dateLabel.textColor;
        [self.contentView addSubview:_dateLabel];
        
        // 未读消息数
        self.badgeView = [JSCustomBadge customBadgeWithString:nil
                                              withStringColor:[UIColor whiteColor]
                                               withInsetColor:[UIColor redColor]
                                               withBadgeFrame:YES
                                          withBadgeFrameColor:[UIColor redColor]
                                                    withScale:.8f withShining:NO];
        [self.contentView addSubview:self.badgeView];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.roomName.backgroundColor = [UIColor clearColor];
        self.roomName.backgroundColor = [UIColor clearColor];
        _dateLabel.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

#pragma mark 重用
- (void)prepareForReuse
{
    [super prepareForReuse];
    _headImage.image = [UIImage imageNamed:@"group_head_default"];
}

#pragma mark 加载子视图
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat cellMarin = 10;
    CGFloat padding = 10;
    
    self.headImage.left = 5;
    self.headImage.top = 5;
    
    [self.badgeView sizeToFit];
    self.badgeView.centerX = self.headImage.right;
    self.badgeView.top = 0.f;
    
    CGFloat textMaxWidth = self.contentView.width - self.headImage.width - cellMarin * 2 - padding;
    CGFloat nameWidth = (textMaxWidth * 2 ) / 3;
    CGFloat dateWidth = textMaxWidth / 3;
    
    // 名字
    self.roomName.frame = CGRectMake(self.headImage.right + padding, self.headImage.top,
                                     nameWidth, self.roomName.font.lineHeight);
    
    // 日期
    self.dateLabel.frame = CGRectMake(self.roomName.right, self.roomName.top,
                                      dateWidth, self.dateLabel.font.lineHeight);
    
    // 消息
    self.roomMessage.frame = CGRectMake(self.roomName.left, self.roomName.bottom + padding,
                                        textMaxWidth, self.roomMessage.font.lineHeight);
    
    // 头像
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSData *photoData = [[[XMPPManager sharedManager] xmppvCardAvatarModule]
                             photoDataForJID:self.roomOccupant.roomJID];
        if (photoData != nil)
            self.headImage.image = [UIImage imageWithData:photoData];
        else
            self.headImage.image = [UIImage imageNamed:@"group_head_default"];
    });
    
}


#pragma mark 更新Cell         // TODO:到底是XMPPRoomMessage还是XMPPRoomOccupant
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[XMPPRoomMessageCoreDataStorageObject class]]) {
        
        XMPPRoomMessageCoreDataStorageObject* cont = (XMPPRoomMessageCoreDataStorageObject*)object;
        self.roomOccupant = cont;
        self.roomName.text = self.roomOccupant.displayName ? self.roomOccupant.displayName : self.roomOccupant.roomJIDStr;
        self.roomMessage.text = [ChatMessageEntityFactory recentContactLastMessageFromJSONString:cont.body];
        self.dateLabel.text = [cont.localTimestamp formatRencentContactDate];
        //[self.headImage setImageWithURL:[NSURL URLWithString:HEAD_IMAGE(contact.bareJid.user)] placeholderImage:[UIImage imageNamed:@"user_head_default"]];
        
        if (self.roomOccupant.unreadMessages.intValue > 0) {
            self.badgeView.hidden = NO;
            [self.badgeView autoBadgeSizeWithString:self.roomOccupant.unreadMessages.stringValue];
        }
        else {
            self.badgeView.hidden = YES;
        }
    } if ([object isKindOfClass:[XMPPRoomOccupantCoreDataStorageObject class]]) {
        
        XMPPRoomOccupantCoreDataStorageObject* cont = (XMPPRoomOccupantCoreDataStorageObject*)object;
        self.roomOccupant = cont;
        self.roomName.text = [self getRoomName:self.roomOccupant.roomJIDStr] ;
        //self.roomMessage.text = [ChatMessageEntityFactory recentContactLastMessageFromJSONString:cont.body];
        //self.dateLabel.text = [cont.localTimestamp formatRencentContactDate];
        //[self.headImage setImageWithURL:[NSURL URLWithString:HEAD_IMAGE(contact.bareJid.user)] placeholderImage:[UIImage imageNamed:@"user_head_default"]];
        
        if (self.roomOccupant.unreadMessages.intValue > 0) {
            self.badgeView.hidden = NO;
            [self.badgeView autoBadgeSizeWithString:self.roomOccupant.unreadMessages.stringValue];
        }
        else {
            self.badgeView.hidden = YES;
        }
        
    }
    return YES;
}


- (NSString *)getRoomName:(NSString *)roomJID
{
    NSString *roomName = [NSString stringWithFormat:@"%@", [roomJID componentsSeparatedByString:@"@"][0]];
    return roomName;
}

 
@end
