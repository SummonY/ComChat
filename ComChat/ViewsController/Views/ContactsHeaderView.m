//
//  ContactsHeaderView.m
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ContactsHeaderView.h"
#import "UIViewAdditions.h"
#import <JSCustomBadge.h>



#define BUTTON_WIDTH        45
#define ASIDE_MARGIN        30



@interface ContactsHeaderView()<UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIButton *addressBookBtn;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UIButton *friendsBookBtn;
@property (nonatomic, strong) UILabel *friendsLabel;
@property (nonatomic, strong) UIButton *groupsBookBtn;
@property (nonatomic, strong) UILabel *groupsLabel;

@property (nonatomic, strong) NSNumber *unscribedNum;
@property (nonatomic, strong) JSCustomBadge *badgeView;

@end


@implementation ContactsHeaderView

#pragma mark 初始化框架
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.width, 45)];
        [self.searchBar setPlaceholder:@"搜索"];
        self.searchBar.delegate = self;
        [self addSubview:self.searchBar];
        
        UIView *friendsAndGroupView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, 65)];
        
        // 设置通信录
        self.addressBookBtn = [[UIButton alloc] initWithFrame:CGRectMake(ASIDE_MARGIN, 5, BUTTON_WIDTH, BUTTON_WIDTH)];
        [self.addressBookBtn setBackgroundImage:[UIImage imageNamed:@"fanpaizi_entry"] forState:UIControlStateNormal];
        [self.addressBookBtn addTarget:self action:@selector(showAddressBook) forControlEvents:UIControlEventTouchUpInside];
        
        self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 15)];
        self.addressLabel.text = @"好友推荐";
        [self.addressLabel setTextColor:[UIColor lightGrayColor]];
        [self.addressLabel setFont:[UIFont systemFontOfSize:15.0f]];
        self.addressLabel.top = self.addressBookBtn.bottom + 2;
        self.addressLabel.centerX = self.addressBookBtn.centerX;
        
        // 设置新的好友
        self.friendsBookBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, BUTTON_WIDTH, BUTTON_WIDTH)];
        [self.friendsBookBtn setBackgroundImage:[UIImage imageNamed:@"friends_book"] forState:UIControlStateNormal];
        [self.friendsBookBtn addTarget:self action:@selector(showFriends) forControlEvents:UIControlEventTouchUpInside];
        
        self.friendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 15)];
        self.friendsLabel.text = @"新的好友";
        [self.friendsLabel setTextColor:[UIColor lightGrayColor]];
        [self.friendsLabel setFont:[UIFont systemFontOfSize:15.0f]];
        
        self.friendsBookBtn.left = self.addressBookBtn.right + ([UIScreen mainScreen].bounds.size.width - ASIDE_MARGIN * 2 - BUTTON_WIDTH * 3) / 2;
        self.friendsLabel.top = self.friendsBookBtn.bottom + 2;
        self.friendsLabel.centerX = self.friendsBookBtn.centerX;
        
        // 设置群组
        self.groupsBookBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 5, BUTTON_WIDTH, BUTTON_WIDTH)];
        [self.groupsBookBtn setBackgroundImage:[UIImage imageNamed:@"groups_book"] forState:UIControlStateNormal];
        [self.groupsBookBtn addTarget:self action:@selector(showGroups) forControlEvents:UIControlEventTouchUpInside];
        
        self.groupsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 15)];
        self.groupsLabel.text = @"群组";
        [self.groupsLabel setTextColor:[UIColor lightGrayColor]];
        [self.groupsLabel setFont:[UIFont systemFontOfSize:15.0f]];
        
        self.groupsBookBtn.right = self.width - ASIDE_MARGIN;
        self.groupsLabel.top = self.groupsBookBtn.bottom + 2;
        self.groupsLabel.centerX = self.groupsBookBtn.centerX;
        
        
        [friendsAndGroupView addSubview:self.addressBookBtn];
        [friendsAndGroupView addSubview:self.addressLabel];
        [friendsAndGroupView addSubview:self.friendsBookBtn];
        [friendsAndGroupView addSubview:self.friendsLabel];
        [friendsAndGroupView addSubview:self.groupsBookBtn];
        [friendsAndGroupView addSubview:self.groupsLabel];
        
        friendsAndGroupView.top = self.searchBar.bottom;
        
        [self addSubview:friendsAndGroupView];
        
        // 未读消息数
        self.badgeView = [JSCustomBadge customBadgeWithString:nil
                                              withStringColor:[UIColor whiteColor]
                                               withInsetColor:[UIColor redColor]
                                               withBadgeFrame:YES
                                          withBadgeFrameColor:[UIColor redColor]
                                                    withScale:.8f withShining:NO];
        [self addSubview:self.badgeView];
        [self.badgeView setHidden:YES];
        self.badgeView.top = friendsAndGroupView.top;
        self.badgeView.right = self.friendsBookBtn.right + 8;
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setUnsubscribedCountNum:)
                                                     name:@"FRIENDS_INVITE_SUBSCRIBED_COUNT_NUM"
                                                   object:nil];
        
    }
    return self;
}


#pragma mark 显示通信录
- (void)showAddressBook
{
    NSLog(@"显示通信录...");
    if (self.delegate && [self.delegate respondsToSelector:@selector(showAllAddressBook)]) {
        [self.delegate showAllAddressBook];
    }
}


#pragma mark 显示新的好友
- (void)showFriends
{
    NSLog(@"显示好友邀请...");
    if (self.delegate && [self.delegate respondsToSelector:@selector(showNewFriends)]) {
        [self.delegate showNewFriends];
    }
}


#pragma mark 显示群组
- (void)showGroups
{
    NSLog(@"显示群组...");
    if (self.delegate && [self.delegate respondsToSelector:@selector(showOrCreateGroups)]) {
        [self.delegate showOrCreateGroups];
    }
}


/*
#pragma mark 更新未添加好友个数
- (BOOL)setUnsubscribedCountNum:(NSNotification *)notification
{
    NSDictionary *unsubscribedDic = [notification userInfo];
    
    self.unscribedNum = [unsubscribedDic objectForKey:@"scribeNum"];
    if ([self.unscribedNum intValue] > 0) {
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = self.unscribedNum.stringValue;
    }
    else {
        self.badgeView.hidden = YES;
    }
    
    return YES;
}
 */

#pragma mark 更新未添加好友个数
- (BOOL)setUnsubscribedCountNum:(NSNumber *)unsubscribedCountNum
{
    if ([unsubscribedCountNum intValue] > 0) {
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = unsubscribedCountNum.stringValue;
    }
    else {
        self.badgeView.hidden = YES;
    }
    
    return YES;
}


#pragma mark 更新未添加好友个数
- (BOOL)resetUnsubscribedCountNum:(NSNumber *)unsubscribedCountNum
{
    if ([unsubscribedCountNum intValue] > 0) {
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = unsubscribedCountNum.stringValue;
    }
    else {
        self.badgeView.hidden = YES;
    }
    
    return YES;
}

/////////////////////////////////////////////////////////////
#pragma mark search delegate
/////////////////////////////////////////////////////////////


#pragma mark 点击搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索联系人...");
    searchBar.showsCancelButton = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchFriends)]) {
        [self.delegate searchFriends];
    }
}

#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"点击取消按钮");
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}




@end
