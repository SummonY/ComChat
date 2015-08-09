//
//  ChatViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/6.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPManager.h"

@interface ChatViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *fetchLaterSignal;
@property (nonatomic, readonly) RACSignal *fetchEarlierSignal;
@property (nonatomic, strong) XMPPJID *buddyJID;
@property (nonatomic, strong) NSMutableArray *earlierResultsSectionArray;
@property (nonatomic, strong) NSMutableArray *totalResultsSectionArray;

- (instancetype)initWithModel:(id)model;

- (NSInteger)numberOfSections;
- (NSString *)titleForHeaderInSection:(NSInteger)section;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (XMPPMessageArchiving_Message_CoreDataObject *)objectAtIndexPath:(NSIndexPath *)indexPath;

- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath;


- (void)fetchEarlierMessage;
- (void)fetchLaterMessage;

- (void)sendMessageWithText:(NSString *)text;
- (void)sendMessageWithImage:(UIImage *)image;
- (void)sendMessageWithData:(NSData *)data time:(NSString *)time;
- (void)sendMessageWithAudioTime:(NSInteger)time data:(NSData *)voiceData urlkey:(NSString *)voiceName;

@end
