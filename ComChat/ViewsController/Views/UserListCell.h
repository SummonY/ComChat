//
//  UserListCell.h
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserListCell : UITableViewCell

- (BOOL)shouldUpdateCellWithObject:(id)object;
- (BOOL)shouldUpdateCellWithSearchObject:(id)object;
- (BOOL)shouldUpdateCellWithRoomMembersObject:(id)object;

@end
