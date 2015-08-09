//
//  UserDetailViewController.h
//  ComChat
//
//  Created by D404 on 15/6/16.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsViewModel.h"
#import <XMPPUserCoreDataStorageObject.h>

@interface UserDetailViewController : UITableViewController

@property (nonatomic, strong) ContactsViewModel *contactsViewModel;

- (instancetype)initWithUser:(NSString *)userName;

@end
