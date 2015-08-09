//
//  UserCategoryCell.h
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UserGroupDelegate;


@interface UserGroupCell : UITableViewCell

@property (nonatomic, strong) UIButton *bgButton;
@property (nonatomic, strong) UILabel *onlineCountSum;

@property (nonatomic, weak) id<UserGroupDelegate> delegate;
- (BOOL)shouldUpdateCellWithObject:(id)object;

@end

@protocol UserGroupDelegate <NSObject>

@optional
- (void)clickUserGroup:(UIButton *)sender;

@end