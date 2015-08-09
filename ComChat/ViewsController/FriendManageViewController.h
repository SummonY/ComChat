//
//  FriendManageViewController.h
//  ComChat
//
//  Created by D404 on 15/7/13.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsViewModel.h"


@interface FriendManageViewController : UITableViewController

- (void)initWithUser:(NSString *)userJid;

@end
