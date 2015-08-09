//
//  XMPPManager.h
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <XMPPFramework.h>
#import <XMPPReconnect.h>
#import <XMPPRoster.h>
#import <XMPPRosterCoreDataStorage.h>
#import <XMPPvCardCoreDataStorage.h>
#import <XMPPCapabilities.h>
#import <XMPPCapabilitiesCoreDataStorage.h>
#import <XMPPMessageArchiving.h>
#import <XMPPMessageArchivingCoreDataStorage.h>
#import <XMPPPresence.h>
#import <XMPPMUC.h>
#import <XMPPRoom.h>
#import <XMPPRoomCoreDataStorage.h>
#import <XMPPRoomMemoryStorage.h>
#import <XMPPRoomHybridStorage.h>
#import <XMPPRoomMessageCoreDataStorageObject.h>
#import <XMPPRoomOccupantCoreDataStorageObject.h>


@protocol XMPPManagerSignalingDelegate;

@interface XMPPManager : NSObject

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong, readonly) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong, readonly) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;

@property (nonatomic, strong, readonly) XMPPMUC *xmppMUC;
@property (nonatomic, strong, readonly) XMPPRoom *xmppRoom;
@property (nonatomic, strong, readonly) id <XMPPRoomStorage> xmppRoomStorage;
@property (nonatomic, strong, readonly) XMPPRoomHybridStorage *xmppHybridStorage;
@property (nonatomic, strong, readonly) XMPPRoomCoreDataStorage *xmppRoomCoreDataStorage;
@property (nonatomic, strong, readonly) XMPPRoomMemoryStorage *xmppRoomMemoryStorage;
@property (nonatomic, strong, readonly) XMPPRoomMessageCoreDataStorageObject *xmppRoomMessageCoreDataStorage;


@property (nonatomic, assign) BOOL customCertEvaluation;
@property (nonatomic, assign) BOOL isXmppConnected;
@property (nonatomic, assign) BOOL goToRegisterAfterConnected;

@property (nonatomic, strong) XMPPJID *myJID;

@property (nonatomic, weak) id<XMPPManagerSignalingDelegate> signalingDelegate;

+ (instancetype)sharedManager;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
- (NSManagedObjectContext *)managedObjectContext_messageArchiving;
- (NSManagedObjectContext *)managedObjectContext_room;


- (BOOL)connectToServer;
- (void)disconnectFromServer;
- (void)connectThenSignIn;
- (void)connectThenSignUp;
- (int)doSignIn;
- (int)doSignUp;

- (void)sendChatMessage:(NSString *)plainMessage toJID:(XMPPJID *)jid;
- (void)sendMessageWithData:(NSData *)data time:(NSString *)name toJID:(XMPPJID *)jid;
- (void)sendChatMessage:(NSString *)plainMessage toGroupJID:(XMPPJID *)groupJid;

- (void)sendSignalingMessage:(NSString *)message toJID:(NSString *)jid;

@end


@protocol XMPPManagerSignalingDelegate <NSObject>

- (void)xmppManager:(XMPPManager *)sender didReceiveSignalingMessage:(XMPPMessage *)message;

@end


