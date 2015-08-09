//
//  RoomMembersListViewController.h
//  ComChat
//
//  Created by D404 on 15/6/23.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomsViewModel.h"

@interface RoomMembersListViewController : UITableViewController

@property (nonatomic, strong) RoomsViewModel *roomsViewModel;

- (instancetype)initWithRoomJid:(NSString *)roomJid;

@end
