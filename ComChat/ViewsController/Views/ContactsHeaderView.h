//
//  ContactsHeaderView.h
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ContactsHeaderDelegate;

@interface ContactsHeaderView : UIView

@property (nonatomic, weak) id<ContactsHeaderDelegate> delegate;

- (BOOL)setUnsubscribedCountNum:(NSNumber *)unsubscribedCountNum;
- (BOOL)resetUnsubscribedCountNum:(NSNumber *)unsubscribedCountNum;

@end


@protocol ContactsHeaderDelegate <NSObject>

@optional

- (void)showAllAddressBook;
- (void)showNewFriends;
- (void)showOrCreateGroups;
- (void)searchFriends;

@end