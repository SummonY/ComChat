//
//  ContactsViewController.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsViewModel.h"
#import "RoomsViewModel.h"

@interface ContactsViewController : UITableViewController


@property (nonatomic, strong) ContactsViewModel *contactsViewModel;
@property (nonatomic, strong) RoomsViewModel *roomsViewModel;

@end
