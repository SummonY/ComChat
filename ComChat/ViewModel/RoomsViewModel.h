//
//  GroupsViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPManager.h"

@interface RoomsViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *updatedContentSignal;
@property (nonatomic, strong) NSManagedObjectContext *roomContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedRoomsResultsController;
@property (nonatomic, strong) NSArray *searchResultArray;
@property (nonatomic, strong, readonly) XMPPRoom *xmppRoom;
@property (nonatomic, strong, readonly) id <XMPPRoomStorage> xmppRoomStorage;

+ (instancetype)sharedViewModel;

- (void)createRoomWithRoomName:(NSString *)roomName;
- (void)registerRoomWithRoomJID:(NSString *)roomJid;
- (void)joinRoomWithRoomJID:(NSString *)roomJid;
- (void)leaveRoomWithRoomJID:(NSString *)roomJid;
- (void)destoryRoomWithRoomJID:(NSString *)roomJid;

- (BOOL)isRoomOwner:(NSString *)userJid;
- (BOOL)isRoomOwnerOrAdmin:(NSString *)userJid;
- (BOOL)isExistedInRoomJid:(NSString *)roomJid;

- (void)searchRooms:(NSString *)searchTerm;
- (void)fetchRoomsList;
- (void)fetchRoomsFromCoreData;
- (void)fetchRoomsInfo:(NSString *)roomJID;
- (void)fetchRoomItems:(NSString *)roomJID;
- (void)fetchRoomMembersList:(NSString *)roomJID;
- (void)inviteUser:(NSString *)userJID inRoom:(NSString *)roomJID;

- (void)fetchRoomBookmarks;


- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfRoomsBookmarkedInSection:(NSInteger)section;
- (id)objectOfRoomsBookmarkedAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSearchItemsInSection:(NSInteger)section;
- (id)objectAtSearchIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)totalNumbersOfRoomAffiliation;
- (NSInteger)numberOfSectionsOfRoomAffiliation;
- (NSString *)titleForHeaderInRoomAffiliationSection:(NSInteger)section;
- (NSInteger)numberOfRoomAffiliationInSection:(NSInteger)section;
- (id)objectAtRoomAffiliationIndexPath:(NSIndexPath *)indexPath;


@end
