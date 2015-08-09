//
//  ContactsViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPManager.h"

@interface ContactsViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *updatedContentSignal;
@property (nonatomic, strong) NSManagedObjectContext *model;
@property (nonatomic, strong) NSFetchedResultsController *fetchedUsersResultsController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedUsersSearchResultsController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedGroupsResultsController;
@property (nonatomic, strong) NSArray *searchResultArray;
@property (nonatomic, readonly) NSNumber *unsubscribedCountNum;

+ (instancetype)sharedViewModel;

- (void)searchContacts:(NSString *)searchTerm;
- (void)fetchUsers;
- (void)fetchGroups;

- (BOOL)isExistInContactsList:(NSString *)userJid;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)objectAtSection:(NSInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSearchItemsInSection:(NSInteger)section;
- (id)objectAtSearchIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfNewItemsInSection:(NSInteger)section;
- (id)objectAtNewIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfInviteUsersInSection:(NSInteger)section;
- (id)objectAtInviteUsersIndexPath:(NSIndexPath *)indexPath;

- (void)resetUnsubscribeContactCount;

@end
