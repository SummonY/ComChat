//
//  MessageViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "MessageViewModel.h"
#import "XMPPManager.h"
#import <RACSubject.h>
#import <ReactiveCocoa.h>
#import "XMPP+IM.h"
#import <XMPPMessage+XEP0045.h>



@interface MessageViewModel()<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RACSubject *updatedContentSignal;
@property (nonatomic, strong) NSManagedObjectContext *model;
@property (nonatomic, strong) NSManagedObjectContext *roomModel;

@property (nonatomic, assign) NSNumber *totalUnreadMessagesNum;
@property (nonatomic, strong) NSFetchedResultsController *fetchedRecentResultsController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedRecentRoomsResultsController;

@end


@implementation MessageViewModel

#pragma mark 共享ViewModel
+ (instancetype)sharedViewModel
{
    static MessageViewModel *_sharedViewModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedViewModel = [[self alloc] init];
    });
    return _sharedViewModel;
}

#pragma mark 初始化
- (instancetype)init
{
    if (self = [super init]) {
        self.model = [[XMPPManager sharedManager] managedObjectContext_messageArchiving];
        self.roomModel = [[XMPPManager sharedManager] managedObjectContext_room];
        
        self.updatedContentSignal = [[RACSubject subject] setNameWithFormat:@"%@ updatedContentSignal", NSStringFromClass([MessageViewModel class])];
        
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppMUC addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        self.totalContactsMessageArray = [[NSMutableArray alloc] init];
        self.totalRoomsMessageArray = [[NSMutableArray alloc] init];
        self.totalResultsMessageArray = [[NSMutableArray alloc] init];
        
        @weakify(self)
        [self.didBecomeActiveSignal subscribeNext:^(id x) {
            @strongify(self);
            [self fetchRecentContacts];
            [self fetchRecentRooms];
        }];
        
        RAC(self, active) = [RACObserve([XMPPManager sharedManager], myJID) map:^id(id value) {
            if (value) {
                return @(YES);
            }
            return @(NO);
        }];
    }
    return self;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppMUC removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 重置未读消息数
- (BOOL)resetUnreadMessageCountForCurrentContact:(XMPPJID *)contactJid
{
    XMPPMessageArchiving_Contact_CoreDataObject *contact = nil;
    XMPPMessageArchiving_Contact_CoreDataObject *currentChatContact = nil;
    
    //for (int i = 0; i < [self numberOfItemsInSection:0]; ++i) {
    for (int i = 0; i < self.totalContactsMessageArray.count; ++i) {
        contact = [self objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([contactJid isEqualToJID:contact.bareJid options:XMPPJIDCompareBare]) {
            currentChatContact = contact;
            break;
        }
    }
    
    if (currentChatContact) {
        // 总数减当前用户的未读消息数
        [self decreaseTotalUnreadMessagesCountWithValue:currentChatContact.unreadMessages.intValue];
        
        XMPPUserCoreDataStorageObject *rosterUser = [[XMPPManager sharedManager].xmppRosterStorage userForJID:currentChatContact.bareJid
                                                                                                   xmppStream:[XMPPManager sharedManager].xmppStream managedObjectContext:[XMPPManager sharedManager].managedObjectContext_roster];
        rosterUser.unreadMessages = @0;
        
        NSError *error = nil;
        if (![[XMPPManager sharedManager].managedObjectContext_roster save:&error]) {
            NSLog(@"重置当前联系人未读消息数失败，%@", [error description]);
        }
        
        currentChatContact.unreadMessages = rosterUser.unreadMessages;
        return YES;
    }
    return NO;
}


#pragma mark 重置群组未读消息数
- (BOOL)resetUnreadMessageCountForCurrentRoom:(XMPPJID *)roomJid
{
    XMPPRoomOccupantCoreDataStorageObject *roomOccupant = nil;
    XMPPRoomOccupantCoreDataStorageObject *currentChatRoomOccupant = nil;
    
    //for (int i = 0; i < [self numberOfItemsInSection:0]; ++i) {
    for (int i = self.totalContactsMessageArray.count; i < self.totalResultsMessageArray.count; ++i) {
        roomOccupant = [self objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([roomJid isEqualToJID:roomOccupant.roomJID options:XMPPJIDCompareBare]) {
            currentChatRoomOccupant = roomOccupant;
            break;
        }
    }
    
    if (currentChatRoomOccupant) {
        // 总数减当前用户的未读消息数
        [self decreaseTotalUnreadMessagesCountWithValue:currentChatRoomOccupant.unreadMessages.intValue];
        
        XMPPRoomOccupantCoreDataStorageObject *occupant = [[XMPPManager sharedManager].xmppRoomCoreDataStorage occupantForJID:currentChatRoomOccupant.jid stream:[XMPPManager sharedManager].xmppStream inContext:[XMPPManager sharedManager].managedObjectContext_room];
        occupant.unreadMessages = @0;
        
        NSError *error = nil;
        if (![[XMPPManager sharedManager].managedObjectContext_room save:&error]) {
            NSLog(@"重置当前群组未读消息数失败，%@", [error description]);
        }
        
        currentChatRoomOccupant.unreadMessages = occupant.unreadMessages;
        return YES;
    }
    return NO;
}


#pragma mark 减少总未读消息数
- (void)decreaseTotalUnreadMessagesCountWithValue:(NSInteger)count
{
    self.totalUnreadMessagesNum = [NSNumber numberWithInt:self.totalUnreadMessagesNum.intValue - count];
}


#pragma mark 删除当前联系人
- (BOOL)deleteRecentContactWithJid:(XMPPJID *)recentContactJId
{
    XMPPMessageArchiving_Contact_CoreDataObject *recentContact =
    [[XMPPManager sharedManager].xmppMessageArchivingCoreDataStorage contactWithJid:recentContactJId
                                                                          streamJid:[XMPPManager sharedManager].myJID
                                                                 managedObjectContext:[XMPPManager sharedManager].managedObjectContext_messageArchiving];
    
    if (recentContact) {
        NSManagedObjectContext *context = [XMPPManager sharedManager].managedObjectContext_messageArchiving;
        [context deleteObject:recentContact];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"删除当前联系人出错%@, %@", error, [error userInfo]);
        }
        
        [self decreaseTotalUnreadMessagesCountWithValue:recentContact.unreadMessages.intValue];
        return YES;
    }
    return NO;
}


#pragma mark 删除当前群组
- (BOOL)deleteRecentRoomWithRoomJid:(XMPPJID *)recentRoomJid
{
    XMPPRoomOccupantCoreDataStorageObject *recentOccupant =
    [[XMPPManager sharedManager].xmppRoomCoreDataStorage occupantForJID:recentRoomJid stream:[XMPPManager sharedManager].xmppStream inContext:[XMPPManager sharedManager].managedObjectContext_room];
    
    if (recentOccupant) {
        NSManagedObjectContext *context = [XMPPManager sharedManager].managedObjectContext_room;
        [context deleteObject:recentOccupant];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"删除当前群组出错%@, %@", error, [error userInfo]);
        }
        
        [self decreaseTotalUnreadMessagesCountWithValue:recentOccupant.unreadMessages.intValue];
        return YES;
    }
    return NO;
}


#pragma mark 删除当前所有联系人
- (BOOL)deleteAllRecentContacts
{
    NSManagedObjectContext *context = [XMPPManager sharedManager].managedObjectContext_messageArchiving;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:NULL];
    if (objects.count > 0) {
        for (NSManagedObject *managedObject in objects) {
            [context deleteObject:managedObject];
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"删除所有联系人出错 %@ %@", error, [error userInfo]);
            return NO;
        }
        
        self.totalUnreadMessagesNum = @0;
        return YES;
    }
    return NO;
}


#pragma mark 删除当前所有群组
- (BOOL)deleteAllRecentRooms
{
    NSManagedObjectContext *context = [XMPPManager sharedManager].managedObjectContext_room;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomOccupantCoreDataStorageObject" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:NULL];
    if (objects.count > 0) {
        for (NSManagedObject *managedObject in objects) {
            [context deleteObject:managedObject];
        }
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"删除所有群组出错 %@ %@", error, [error userInfo]);
            return NO;
        }
        
        self.totalUnreadMessagesNum = @0;
        return YES;
    }
    return NO;
}



#pragma mark 获取当前联系人
- (void)fetchRecentContacts
{
    NSLog(@"获取当前通信联系人...");
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"streamBareJidStr = '%@'", [XMPPManager sharedManager].myJID.bare]];
    [self.fetchedRecentResultsController.fetchRequest setPredicate:filterPredicate];
    
    NSError *error = nil;
    if (![self.fetchedRecentResultsController performFetch:&error]) {
        NSLog(@"获取通信联系人出错, %@", error);
    } else {
        [self.totalContactsMessageArray removeAllObjects];
        
        if ([self.fetchedRecentResultsController fetchedObjects].count > 0) {
            for (XMPPMessageArchiving_Contact_CoreDataObject *contact in [self.fetchedRecentResultsController fetchedObjects]) {
                [self.totalContactsMessageArray addObject:contact];
            }
            [self updateUserDisplayName];
        }
    }
}


#pragma mark 获取当前联系人
- (void)fetchRecentRooms
{
    NSLog(@"获取当前通信群组...");
    //NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"streamBareJidStr = '%@'", [XMPPManager sharedManager].myJID.bare]];
    //[self.fetchedRecentRoomsResultsController.fetchRequest setPredicate:filterPredicate];
    
    [self setPredicateForFetchRooms];
    
    NSError *error = nil;
    if (![self.fetchedRecentRoomsResultsController performFetch:&error]) {
        NSLog(@"获取通信联系人出错, %@", error);
    } else {
        [self.totalRoomsMessageArray removeAllObjects];
        
        if ([self.fetchedRecentRoomsResultsController fetchedObjects].count > 0) {
            for (XMPPRoomMessageCoreDataStorageObject *roomMessage in [self.fetchedRecentRoomsResultsController fetchedObjects]) {
                if (![self isExistedInRoomsMessageArray:self.totalRoomsMessageArray toRoomJid:roomMessage.roomJIDStr]) {
                    [self.totalRoomsMessageArray addObject:roomMessage];
                }
            }
            [self updateRoomDisplayName];
        }
    }
}


#pragma mark 判断群组是否已经在当前通讯消息数组中
- (BOOL)isExistedInRoomsMessageArray:(NSMutableArray *)recentRoomsArray toRoomJid:(NSString *)roomJIDStr
{
    for (XMPPRoomMessageCoreDataStorageObject *roomMessage in recentRoomsArray) {
        if ([roomJIDStr isEqualToString:roomMessage.roomJIDStr]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark 合并获取到的结果
- (void)mergeAllFetchedResults
{
    NSLog(@"合并获取到的当前聊天联系人和群组...");
    @synchronized(self) {
        [self.totalResultsMessageArray removeAllObjects];
        
        // 合并当前聊天联系人和群组
        if (self.totalContactsMessageArray.count) {
            for (XMPPMessageArchiving_Contact_CoreDataObject *contact in self.totalContactsMessageArray) {
                [self.totalResultsMessageArray addObject:contact];
            }
        }
        if (self.totalRoomsMessageArray.count) {              // TODO:单聊和群聊混合显示
            for (XMPPRoomMessageCoreDataStorageObject *roomMessage in self.totalRoomsMessageArray) {
                [self.totalResultsMessageArray addObject:roomMessage];
            }
        }
        //NSLog(@"联系人和群组合并之后的消息结果：%@", self.totalResultsMessageArray);
    }
}

#pragma mark 返回全部联系人和群组的消息数组
- (NSMutableArray *)totalResultsMessageArray
{
    @synchronized(self) {
        return _totalResultsMessageArray;
    }
}


#pragma mark 更新用户显示名称
- (void)updateUserDisplayName
{
    NSLog(@"更新用户displayName");
    NSArray *array = [self.fetchedRecentResultsController fetchedObjects];
    NSInteger totalUnreadCount = 0;
    
    if (array.count > 0) {
        XMPPUserCoreDataStorageObject *rosterUser = nil;
        for (XMPPMessageArchiving_Contact_CoreDataObject *contact in array) {
            rosterUser = [[XMPPManager sharedManager].xmppRosterStorage userForJID:contact.bareJid
                                                                        xmppStream:[XMPPManager sharedManager].xmppStream managedObjectContext:[XMPPManager sharedManager].managedObjectContext_roster];
            contact.displayName = rosterUser.displayName;
            contact.unreadMessages = rosterUser.unreadMessages;
            
            totalUnreadCount = totalUnreadCount + contact.unreadMessages.intValue;
        }
        self.totalUnreadMessagesNum = [NSNumber numberWithInt:totalUnreadCount];
    }
    //[(RACSubject *)self.updatedContentSignal sendNext:nil];
}


#pragma mark 更新群组显示名称
- (void)updateRoomDisplayName
{
    NSLog(@"更新群组displayName...");
    NSArray *array = [self.fetchedRecentRoomsResultsController fetchedObjects];
    NSInteger totalUnreadCount = 0;
    
    if (array.count > 0) {
        XMPPRoomOccupantCoreDataStorageObject *roomOccupant = nil;
        for (XMPPRoomOccupantCoreDataStorageObject *occupant in array) {
            roomOccupant = [[XMPPManager sharedManager].xmppRoomCoreDataStorage occupantForJID:occupant.jid stream:[XMPPManager sharedManager].xmppStream inContext:[XMPPManager sharedManager].managedObjectContext_room];
            occupant.displayName = roomOccupant.roomJIDStr;
            occupant.unreadMessages = roomOccupant.unreadMessages;
            
            totalUnreadCount = totalUnreadCount + occupant.unreadMessages.intValue;
        }
        self.totalUnreadMessagesNum = [NSNumber numberWithInt:totalUnreadCount];
    }
    //[(RACSubject *)self.updatedContentSignal sendNext:nil];
}


///////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
//////////////////////////////////////////////////////////////////////////


#pragma mark 获得当前结果控制器
- (NSFetchedResultsController *)fetchedRecentResultsController
{
    NSLog(@"获取当前通信联系人，按时间倒序返回...");
    if (!_fetchedRecentResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Contact_CoreDataObject" inManagedObjectContext:self.model];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"mostRecentMessageTimestamp" ascending:NO];   // 按时间排序
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        _fetchedRecentResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.model sectionNameKeyPath:nil cacheName:nil];
        [_fetchedRecentResultsController setDelegate:self];
    }
    return _fetchedRecentResultsController;
}

#pragma mark 设置谓词来获取联系人
- (void)setPredicateForFetchRooms
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"streamBareJidStr = '%@'", [XMPPManager sharedManager].myJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"affiliation != 'none'"];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedRecentRoomsResultsController.fetchRequest setPredicate:predicate];
}


#pragma mark 获取用户出席群组
- (NSFetchedResultsController *)fetchedRecentRoomsResultsController
{
    NSLog(@"获取当前通信群组，按时间倒序返回...");
    if (!_fetchedRecentRoomsResultsController) {
        //NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomMessageCoreDataStorageObject" inManagedObjectContext:self.roomModel];
        //NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:NO];       // 按时间排序
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomOccupantCoreDataStorageObject" inManagedObjectContext:self.roomModel];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];       // 按时间排序
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        _fetchedRecentRoomsResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.roomModel sectionNameKeyPath:nil cacheName:nil];
        [_fetchedRecentRoomsResultsController setDelegate:self];
    }
    return _fetchedRecentRoomsResultsController;
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"消息控制器内容变化...");
    [self fetchRecentContacts];
    [self fetchRecentRooms];
    [(RACSubject *)self.updatedContentSignal sendNext:nil];
    [self mergeAllFetchedResults];
}



//////////////////////////////////////////////////////////////////////////////////////
#pragma mark DataSource
//////////////////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"返回总联系人和群组通信消息个数: %lu", (unsigned long)[self.totalResultsMessageArray count]);
    return [self.totalResultsMessageArray count];
}


- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.totalResultsMessageArray objectAtIndex:indexPath.row];
}


#pragma mark 删除行联系人或群组
-(void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    id objectMessage = [self.totalResultsMessageArray objectAtIndex:indexPath.row];
    
    if ([objectMessage isKindOfClass:[XMPPMessageArchiving_Contact_CoreDataObject class]]) {
        NSManagedObject *object = [self.fetchedRecentResultsController objectAtIndexPath:indexPath];
        NSManagedObjectContext *context = [self.fetchedRecentResultsController managedObjectContext];
        
        if (object) {
            [context deleteObject:object];
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"删除用户消息错误 %@, %@", error, [error userInfo]);
            }
        }
    } else if ([objectMessage isKindOfClass:[XMPPRoomMessageCoreDataStorageObject class]]) {
        NSManagedObject *object = [self.fetchedRecentRoomsResultsController objectAtIndexPath:indexPath];
        NSManagedObjectContext *context = [self.fetchedRecentRoomsResultsController managedObjectContext];
        
        if (object) {
            [context deleteObject:object];
            
            NSError *error = nil;
            if (![context save:&error]) {
                NSLog(@"删除群组消息错误 %@, %@", error, [error userInfo]);
            }
        }
    }
}


-(void)deleteObjectOfRoomAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedRecentRoomsResultsController objectAtIndexPath:indexPath];
    NSManagedObjectContext *context = [self.fetchedRecentRoomsResultsController managedObjectContext];
    
    if (object) {
        [context deleteObject:object];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"删除群组消息错误 %@, %@", error, [error userInfo]);
        }
    }
}




@end
