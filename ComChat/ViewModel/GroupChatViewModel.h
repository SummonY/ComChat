//
//  GroupChatViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPManager.h"

@interface GroupChatViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *fetchRoomLaterSignal;
@property (nonatomic, readonly) RACSignal *fetchRoomEarlierSignal;
@property (nonatomic, strong) XMPPJID *groupJID;
@property (nonatomic, strong) NSMutableArray *earlierResultsSectionArray;
@property (nonatomic, strong) NSMutableArray *totalResultsSectionArray;

- (instancetype)initWithModel:(id)model;

- (NSInteger)numberOfSections;
- (NSString *)titleForHeaderInSection:(NSInteger)section;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (XMPPRoomMessageCoreDataStorageObject *)objectAtIndexPath:(NSIndexPath *)indexPath;

- (void)fetchRoomEarlierMessage;
- (void)fetchRoomLaterMessage;

- (void)sendMessageWithText:(NSString *)text;
- (void)sendMessageWithImage:(UIImage *)image;
- (void)sendMessageWithAudioTime:(NSInteger)time data:(NSData *)voiceData urlkey:(NSString *)voiceName;

@end
