//
//  NewFriendsCell.h
//  ComChat
//
//  Created by D404 on 15/6/13.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NewFriendsDelegate;


@interface NewFriendsCell : UITableViewCell

@property (nonatomic, weak) id<NewFriendsDelegate> delegate;

- (BOOL)shouldUpdateCellWithObject:(id)object;

@end


@protocol NewFriendsDelegate <NSObject>

@optional
- (void)agreeAddFriend:(NSString *)userJID;
- (void)rejectAddFriend:(NSString *)userJID;

@end