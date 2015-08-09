//
//  RoomProfileViewController.h
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "RoomsViewModel.h"

@interface RoomProfileViewController : UITableViewController

@property (nonatomic, strong) RoomsViewModel *roomsViewModel;

- (void)initWithRoomJID:(XMPPJID *)roomJID;

@end
