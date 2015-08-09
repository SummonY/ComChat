//
//  XMPPManager.m
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "XMPPManager.h"
#import "Macros.h"
#import <XMPPMessage+XEP0045.h>
#import <XMPPMessage+XEP_0085.h>
#import "XMPPMessage+Signaling.h"

@interface XMPPManager()

@end


@implementation XMPPManager

#pragma mark 共享管理类
+ (instancetype)sharedManager
{
    static XMPPManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
        [_sharedManager setupStream];
    });
    return _sharedManager;
}

#pragma mark 设置Stream流
- (void)setupStream
{
    NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
    /* 初始化xmppStream*/
    _xmppStream = [[XMPPStream alloc] init];
    _xmppStream.enableBackgroundingOnSocket = YES;  // 使能后台socket
    
    /* 设置重新连接 */
    _xmppReconnect = [[XMPPReconnect alloc] init];
    
    /* 设置名册Roster */
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _xmppRosterStorage.autoRemovePreviousDatabaseFile = NO;
    _xmppRosterStorage.autoRecreateDatabaseFile = NO;
    
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    _xmppRoster.autoFetchRoster = YES;
    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    
    /* 设置电子名片vCard */
    _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
    
    /* 设置功能 */
    _xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
    _xmppCapabilities.autoFetchHashedCapabilities = YES;
    _xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    /* 设置信息存档 */
    _xmppMessageArchivingCoreDataStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage];
    
    // 设置房间
    _xmppRoomCoreDataStorage = [[XMPPRoomCoreDataStorage alloc] init];
    _xmppRoomCoreDataStorage.autoRecreateDatabaseFile = NO;
    _xmppRoomCoreDataStorage.autoRemovePreviousDatabaseFile = NO;
    
    //_xmppRoomStorage = [XMPPRoomHybridStorage sharedInstance];
    _xmppMUC = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
    
    /* 激活XMPP 模块 */
    [_xmppReconnect         activate:_xmppStream];
    [_xmppRoster            activate:_xmppStream];
    [_xmppvCardTempModule   activate:_xmppStream];
    [_xmppvCardAvatarModule activate:_xmppStream];
    [_xmppCapabilities      activate:_xmppStream];
    [_xmppMessageArchiving  activate:_xmppStream];
    [_xmppRoom              activate:_xmppStream];
    [_xmppMUC               activate:_xmppStream];
    
    [_xmppStream            addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoster            addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppMessageArchiving  addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppMUC               addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoom              addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppvCardAvatarModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    /* 设置与和端口号，端口号默认为5222 */
    //[_xmppStream setHostName:@"125.220.159.168"];
    //[_xmppStream setHostPort:5222];
    _customCertEvaluation = YES;
}

#pragma mark 关闭xmppstream
- (void)teardownStream
{
    [_xmppStream            removeDelegate:self];
    [_xmppRoster            removeDelegate:self];
    [_xmppMessageArchiving  removeDelegate:self];
    [_xmppRoom              removeDelegate:self];
    
    [_xmppReconnect         deactivate];
    [_xmppRoster            deactivate];
    [_xmppvCardTempModule   deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppCapabilities      deactivate];
    [_xmppMessageArchiving  deactivate];
    [_xmppRoom              deactivate];
    
    [_xmppStream disconnect];
    
    _xmppStream = nil;
    _xmppReconnect = nil;
    _xmppRoster = nil;
    _xmppRosterStorage = nil;
    _xmppvCardStorage = nil;
    _xmppvCardTempModule = nil;
    _xmppvCardAvatarModule = nil;
    _xmppCapabilities = nil;
    _xmppCapabilitiesStorage = nil;
    _xmppMessageArchiving = nil;
    _xmppMessageArchivingCoreDataStorage = nil;
    
    _xmppRoom = nil;
    _xmppRoomCoreDataStorage = nil;
    _xmppRoomMessageCoreDataStorage = nil;
}


#pragma mark 使用户上线
- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}


#pragma mark 使用户下线
- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

#pragma mark 连接服务器
- (BOOL)connectToServer
{
    NSError *error = nil;
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:XMPP_USER_ID];
    NSLog(@"用户%@ 请求建立服务器连接！", userID);
    if (userID == nil) {
        return NO;
    }
    
    [_xmppStream setMyJID:[XMPPJID jidWithUser:userID domain:XMPP_DOMAIN resource:XMPP_RESOURCE]];
    [_xmppStream setHostName:XMPP_HOST_NAME];
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        NSLog(@"连接超时！%@", error);
        return NO;
    }
    return YES;
}

#pragma mark 从服务器断开
- (void)disconnectFromServer
{
    [self goOffline];
    [_xmppStream disconnect];
}

#pragma mark 建立服务器连接成功后登录
- (void)connectThenSignIn
{
    if ([_xmppStream isConnecting]) {   // 连接出错，正在建立连接
        return ;
    }
    
    if ([_xmppStream isDisconnected]) {     // 若断开，则建立服务器连接
        [self connectToServer];
        _goToRegisterAfterConnected = NO;
    } else if ([_xmppStream isConnected]) {
        [self doSignIn];
    }
}


#pragma mark 执行登录操作
- (int)doSignIn
{
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:XMPP_USER_ID];
    NSString *userPW = [[NSUserDefaults standardUserDefaults] objectForKey:XMPP_PASSWORD];
    NSLog(@"用户%@ 带有密码:%@，正在验证身份...", userID, userPW);
    if (userID == nil || userPW == nil) {
        NSLog(@"用户ID或密码设置有误.");
        return -1;
    }
    
    NSError *error = nil;
    if (![_xmppStream authenticateWithPassword:userPW error:&error]) {   // 验证用户名密码
        NSLog(@"用户名或密码错误！%@", error);
        return 0;
    }
    if ([_xmppStream isAuthenticating]) {
        NSLog(@"正在认证...");
    }
    
    return 1;
}

#pragma mark 连接服务器后注册
- (void)connectThenSignUp
{
    if ([_xmppStream isConnecting]) {   // 连接出错，正在建立连接
        return ;
    }
    
    if ([_xmppStream isDisconnected]) {     // 若断开，则建立服务器连接
        [self connectToServer];
        _goToRegisterAfterConnected = YES;
    } else if ([_xmppStream isConnected]) {
        [self doSignUp];
    }
}

#pragma mark 执行注册操作
- (int)doSignUp
{
    NSError *error = nil;
    
    if ([_xmppStream isConnected] && [_xmppStream supportsInBandRegistration]) {
        NSString *userID = [[NSUserDefaults standardUserDefaults] stringForKey:XMPP_USER_ID];
        NSString *userPW = [[NSUserDefaults standardUserDefaults] stringForKey:XMPP_PASSWORD];
        NSLog(@"用户%@, 请求进行注册...", userID);
        if (userID == nil || userPW == nil) {
            return -1;
        }
        
        [_xmppStream setMyJID:[XMPPJID jidWithUser:userID domain:XMPP_DOMAIN resource:XMPP_RESOURCE]];
        if (![_xmppStream registerWithPassword:userPW error:&error]) {
            NSLog(@"注册失败，%@", error);
            return 0;
        }
        if ([_xmppStream isAuthenticating]) {
            NSLog(@"正在认证...");
        }
        
    }
    else {
        NSLog(@"XMPPStream未连接，或XMPPStream不支持带内注册");
    }
    return 0;
}

#pragma mark 发送消息
- (void)sendChatMessage:(NSString *)plainMessage toJID:(XMPPJID *)jid
{
    if (plainMessage.length > 0 && jid.user.length > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:plainMessage];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:jid.full];
        
        [message addChild:body];
        
        XMPPMessage * xMessage = [XMPPMessage messageFromElement:message];
        [xMessage addActiveChatState];
        
        [[XMPPManager sharedManager].xmppStream sendElement:message];
    }
}


/** 发送二进制文件 */
- (void)sendMessageWithData:(NSData *)data time:(NSString *)time toJID:(XMPPJID *)jid
{
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:jid];
    
    [message addBody:time];
    
    // 转换成base64的编码
    NSString *base64str = [data base64EncodedStringWithOptions:0];
    
    // 设置节点内容
    XMPPElement *attachment = [XMPPElement elementWithName:@"attachment" stringValue:base64str];
    
    // 包含子节点
    [message addChild:attachment];
    
    // 发送消息
    [[XMPPManager sharedManager].xmppStream sendElement:message];
}


#pragma mark 发送信号消息
- (void)sendSignalingMessage:(NSString *)message toJID:(NSString *)jid
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    XMPPJID *toJID = [XMPPJID jidWithString:jid];
    
    XMPPMessage *xmppMessage = [XMPPMessage signalineMessageTo:toJID elementID:Nil child:body];
    [[XMPPManager sharedManager].xmppStream sendElement:xmppMessage];
}



#pragma mark 向群组所有人发送消息
- (void)sendChatMessage:(NSString *)plainMessage toGroupJID:(XMPPJID *)groupJid
{
    if (plainMessage.length > 0 && ![groupJid.full isEqualToString:@""]) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:plainMessage];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
        [message addAttributeWithName:@"to" stringValue:groupJid.full];
        
        [message addChild:body];
        
        [[XMPPManager sharedManager].xmppStream sendElement:message];
    }
}


//////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream delegate
//////////////////////////////////////////////////////////////////////

/**
 * This method is called before the stream begins the connection process.
 *
 * If developing an iOS app that runs in the background, this may be a good place to indicate
 * that this is a task that needs to continue running in the background.
 **/
- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream将要建立XMPPStream连接...:%@", sender);
}

/**
 * This method is called after the tcp socket has connected to the remote host.
 * It may be used as a hook for various things, such as updating the UI or extracting the server's IP address.
 *
 * If developing an iOS app that runs in the background,
 * please use XMPPStream's enableBackgroundingOnSocket property as opposed to doing it directly on the socket here.
 **/
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    NSLog(@"XMPPManager xmppStream socket连接建立成功!%@", socket);
}

/**
 * This method is called after a TCP connection has been established with the server,
 * and the opening XML stream negotiation has started.
 **/
- (void)xmppStreamDidStartNegotiation:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream进入XMPPStream开始协商..., %@", sender);
}

/**
 * This method is called immediately prior to the stream being secured via TLS/SSL.
 * Note that this delegate may be called even if you do not explicitly invoke the startTLS method.
 * Servers have the option of requiring connections to be secured during the opening process.
 * If this is the case, the XMPPStream will automatically attempt to properly secure the connection.
 *
 * The possible keys and values for the security settings are well documented.
 * Some possible keys are:
 * - kCFStreamSSLLevel
 * - kCFStreamSSLAllowsExpiredCertificates
 * - kCFStreamSSLAllowsExpiredRoots
 * - kCFStreamSSLAllowsAnyRoot
 * - kCFStreamSSLValidatesCertificateChain
 * - kCFStreamSSLPeerName
 * - kCFStreamSSLCertificates
 *
 * Please refer to Apple's documentation for associated values, as well as other possible keys.
 *
 * The dictionary of settings is what will be passed to the startTLS method of ther underlying AsyncSocket.
 * The AsyncSocket header file also contains a discussion of the security consequences of various options.
 * It is recommended reading if you are planning on implementing this method.
 *
 * The dictionary of settings that are initially passed will be an empty dictionary.
 * If you choose not to implement this method, or simply do not edit the dictionary,
 * then the default settings will be used.
 * That is, the kCFStreamSSLPeerName will be set to the configured host name,
 * and the default security validation checks will be performed.
 *
 * This means that authentication will fail if the name on the X509 certificate of
 * the server does not match the value of the hostname for the xmpp stream.
 * It will also fail if the certificate is self-signed, or if it is expired, etc.
 *
 * These settings are most likely the right fit for most production environments,
 * but may need to be tweaked for development or testing,
 * where the development server may be using a self-signed certificate.
 **/
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    NSLog(@"XMPPManager xmppStream将要进入安全设置...");
}

/**
 * This method is called after the stream has been secured via SSL/TLS.
 * This method may be called if the server required a secure connection during the opening process,
 * or if the secureConnection: method was manually invoked.
 **/
- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream已经采用SSL/TLS.");
}

/**
 * This method is called after the XML stream has been fully opened.
 * More precisely, this method is called after an opening <xml/> and <stream:stream/> tag have been sent and received,
 * and after the stream features have been received, and any required features have been fullfilled.
 * At this point it's safe to begin communication with the server.
 **/
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream XMPPStream已经连接");
    _isXmppConnected = YES;
    
    if (_goToRegisterAfterConnected) {
        [self doSignUp];
    }
    else {
        [self doSignIn];
    }
}

/**
 * This method is called after registration of a new user has successfully finished.
 * If registration fails for some reason, the xmppStream:didNotRegister: method will be called instead.
 **/
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream用户注册成功");
}

/**
 * This method is called if registration fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    NSLog(@"XMPPManager xmppStream用户注册失败");
}

/**
 * This method is called after authentication has successfully finished.
 * If authentication fails for some reason, the xmppStream:didNotAuthenticate: method will be called instead.
 **/
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream用户认证通过");
    _myJID = _xmppStream.myJID;
    [self goOnline];
}

/**
 * This method is called if authentication fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"XMPPManager xmppStream用户认证失败, error = %@", error);
}

/**
 * This method is called if the XMPP server doesn't allow our resource of choice
 * because it conflicts with an existing resource.
 *
 * Return an alternative resource or return nil to let the server automatically pick a resource for us.
 **/
/*
- (NSString *)xmppStream:(XMPPStream *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource
{
    
}
*/

/**
 * These methods are called before their respective XML elements are broadcast as received to the rest of the stack.
 * These methods can be used to modify elements on the fly.
 * (E.g. perform custom decryption so the rest of the stack sees readable text.)
 *
 * You may also filter incoming elements by returning nil.
 *
 * When implementing these methods to modify the element, you do not need to copy the given element.
 * You can simply edit the given element, and return it.
 * The reason these methods return an element, instead of void, is to allow filtering.
 *
 * Concerning thread-safety, delegates implementing the method are invoked one-at-a-time to
 * allow thread-safe modification of the given elements.
 *
 * You should NOT implement these methods unless you have good reason to do so.
 * For general processing and notification of received elements, please use xmppStream:didReceiveX: methods.
 *
 * @see xmppStream:didReceiveIQ:
 * @see xmppStream:didReceiveMessage:
 * @see xmppStream:didReceivePresence:
 **/
/*
- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq
{
    
}
- (XMPPMessage *)xmppStream:(XMPPStream *)sender willReceiveMessage:(XMPPMessage *)message
{
    
}
- (XMPPPresence *)xmppStream:(XMPPStream *)sender willReceivePresence:(XMPPPresence *)presence
{
    
}
*/

/**
 * These methods are called after their respective XML elements are received on the stream.
 *
 * In the case of an IQ, the delegate method should return YES if it has or will respond to the given IQ.
 * If the IQ is of type 'get' or 'set', and no delegates respond to the IQ,
 * then xmpp stream will automatically send an error response.
 *
 * Concerning thread-safety, delegates shouldn't modify the given elements.
 * As documented in NSXML / KissXML, elements are read-access thread-safe, but write-access thread-unsafe.
 * If you have need to modify an element for any reason,
 * you should copy the element first, and then modify and use the copy.
 **/
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"XMPPManager xmppStream接收到IQ包");
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"XMPPManager xmppStream接收到消息");
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppStream接收到presence");
}


/**
 * This method is called if an XMPP error is received.
 * In other words, a <stream:error/>.
 *
 * However, this method may also be called for any unrecognized xml stanzas.
 *
 * Note that standard errors (<iq type='error'/> for example) are delivered normally,
 * via the other didReceive...: methods.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error
{
    NSLog(@"XMPPManager xmppStream接收到错误,%@", error);
}

/**
 * These methods are called before their respective XML elements are sent over the stream.
 * These methods can be used to modify outgoing elements on the fly.
 * (E.g. add standard information for custom protocols.)
 *
 * You may also filter outgoing elements by returning nil.
 *
 * When implementing these methods to modify the element, you do not need to copy the given element.
 * You can simply edit the given element, and return it.
 * The reason these methods return an element, instead of void, is to allow filtering.
 *
 * Concerning thread-safety, delegates implementing the method are invoked one-at-a-time to
 * allow thread-safe modification of the given elements.
 *
 * You should NOT implement these methods unless you have good reason to do so.
 * For general processing and notification of sent elements, please use xmppStream:didSendX: methods.
 *
 * @see xmppStream:didSendIQ:
 * @see xmppStream:didSendMessage:
 * @see xmppStream:didSendPresence:
 **/

/*
- (XMPPIQ *)xmppStream:(XMPPStream *)sender willSendIQ:(XMPPIQ *)iq
{
    NSLog(@"将要发送IQ包%@", iq);
}
- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message
{
    NSLog(@"将要发送消息:%@", message);
}
- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence
{
    NSLog(@"将要发送Presence:%@", presence);
}
*/

/**
 * These methods are called after their respective XML elements are sent over the stream.
 * These methods may be used to listen for certain events (such as an unavailable presence having been sent),
 * or for general logging purposes. (E.g. a central history logging mechanism).
 **/
- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq
{
    NSLog(@"XMPPManager xmppStream已发送IQ包");
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"XMPPManager xmppStream已发送信息");
}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppStream已发送在线presence");
}

/**
 * These methods are called after failing to send the respective XML elements over the stream.
 **/
- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
     NSLog(@"XMPPManager xmppStream发送IQ包失败, %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    NSLog(@"XMPPManager xmppStream发送信息失败， %@", error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    NSLog(@"XMPPManager xmppStream发送在线presence失败, %@", error);
}

/**
 * This method is called if the XMPP Stream's jid changes.
 **/
- (void)xmppStreamDidChangeMyJID:(XMPPStream *)xmppStream
{
    NSLog(@"XMPPManager xmppStream初始化JID");
}

/**
 * This method is called if the disconnect method is called.
 * It may be used to determine if a disconnection was purposeful, or due to an error.
 **/
- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream告知断开连接");
}

/**
 * This methods is called if the XMPP Stream's connect times out
 **/
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    NSLog(@"XMPPManager xmppStream连接超时");
}

/**
 * This method is called after the stream is closed.
 *
 * The given error parameter will be non-nil if the error was due to something outside the general xmpp realm.
 * Some examples:
 * - The TCP socket was unexpectedly disconnected.
 * - The SRV resolution of the domain failed.
 * - Error parsing xml sent from server.
 **/
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"XMPPManager xmppStream断开连接,%@, %@", error, [error description]);
    if ([error description]) {
        [self connectToServer];
    }
}

/**
 * This method is only used in P2P mode when the connectTo:withAddress: method was used.
 *
 * It allows the delegate to read the <stream:features/> element if/when they arrive.
 * Recall that the XEP specifies that <stream:features/> SHOULD be sent.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures
{
    NSLog(@"XMPPManager xmppStream接收到P2P属性");
}

/**
 * This method is only used in P2P mode when the connectTo:withSocket: method was used.
 *
 * It allows the delegate to customize the <stream:features/> element,
 * adding any specific featues the delegate might support.
 **/
- (void)xmppStream:(XMPPStream *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures
{
    NSLog(@"XMPPManager xmppStream将要发送P2P");
}

/**
 * These methods are called as xmpp modules are registered and unregistered with the stream.
 * This generally corresponds to xmpp modules being initailzed and deallocated.
 *
 * The methods may be useful, for example, if a more precise auto delegation mechanism is needed
 * than what is available with the autoAddDelegate:toModulesOfClass: method.
 **/
- (void)xmppStream:(XMPPStream *)sender didRegisterModule:(id)module
{
    NSLog(@"XMPPManager xmppStream 已注册Module");
}


- (void)xmppStream:(XMPPStream *)sender willUnregisterModule:(id)module
{
    NSLog(@"XMPPManager xmppStream解除注册Module");
}

//////////////////////////////////////////////////////////
#pragma mark XMPP Roster Delegate
//////////////////////////////////////////////////////////



/**
 * Sent when a presence subscription request is received.
 * That is, another user has added you to their roster,
 * and is requesting permission to receive presence broadcasts that you send.
 *
 * The entire presence packet is provided for proper extensibility.
 * You can use [presence from] to get the JID of the user who sent the request.
 *
 * The methods acceptPresenceSubscriptionRequestFrom: and rejectPresenceSubscriptionRequestFrom: can
 * be used to respond to the request.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppRoster接收到在线用户请求");
}

/**
 * Sent when a Roster Push is received as specified in Section 2.1.6 of RFC 6121.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq
{
    NSLog(@"XMPPManager xmppRoster接收到Roster推送");
}

/**
 * Sent when the initial roster is received.
 **/
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender
{
    NSLog(@"XMPPManager xmppRoster开始Populating");
}

/**
 * Sent when the initial roster has been populated into storage.
 **/
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    NSLog(@"XMPPManager xmppRoster结束Populating");
}

/**
 * Sent when the roster receives a roster item.
 *
 * Example:
 *
 * <item jid='romeo@example.net' name='Romeo' subscription='both'>
 *   <group>Friends</group>
 * </item>
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item
{
    NSLog(@"XMPPManager xmppRoster接收到RosterIterm");
}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRoomDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark 创建聊天室成功
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"XMPPManager xmppRoom聊天室已创建");
}

/**
 * Invoked with the results of a request to fetch the configuration form.
 * The given config form will look something like:
 *
 * <x xmlns='jabber:x:data' type='form'>
 *   <title>Configuration for MUC Room</title>
 *   <field type='hidden'
 *           var='FORM_TYPE'>
 *     <value>http://jabber.org/protocol/muc#roomconfig</value>
 *   </field>
 *   <field label='Natural-Language Room Name'
 *           type='text-single'
 *            var='muc#roomconfig_roomname'/>
 *   <field label='Enable Public Logging?'
 *           type='boolean'
 *            var='muc#roomconfig_enablelogging'>
 *     <value>0</value>
 *   </field>
 *   ...
 * </x>
 *
 * The form is to be filled out and then submitted via the configureRoomUsingOptions: method.
 *
 * @see fetchConfigurationForm:
 * @see configureRoomUsingOptions:
 **/
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    NSLog(@"XMPPManager xmppRoom获取到配置格式");
}

- (void)xmppRoom:(XMPPRoom *)sender willSendConfiguration:(XMPPIQ *)roomConfigForm
{
    NSLog(@"XMPPManager xmppRoom将要发送配置信息");
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"XMPPManager xmppRoom配置完成. ");
}

- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"XMPPManager xmppRoom配置失败");
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"XMPPManager xmppRoom已经加入群组, %@", sender);
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender
{
    NSLog(@"XMPPManager xmppRoom已经离开群组");
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender
{
    NSLog(@"XMPPManager xmppRoom群组已解散");
}

#pragma mark 加入群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppRoom创建者已经加入群组, JID = %@, presence = %@", occupantJID, presence);
}

#pragma mark 离开群组
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppRoom创建者离开群组, JID = %@, presence = %@", occupantJID, presence);
}

#pragma mark 群组更新
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"XMPPManager xmppRoom创建者更新, JID = %@, presence = %@", occupantJID, presence);
}

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room, or from a non-occupant.
 **/
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    NSLog(@"XMPPManager xmppRoom接收到消息");
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
    NSLog(@"XMPPManager xmppRoom获取禁止名单列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError
{
    NSLog(@"XMPPManager xmppRoom获取禁止名单列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
    NSLog(@"XMPPManager xmppRoom获取成员列表成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError
{
    NSLog(@"XMPPManager xmppRoom获取成员列表失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
    NSLog(@"XMPPManager xmppRoom获取ModeratorsList成功, %@", items);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError
{
    NSLog(@"XMPPManager xmppRoom获取ModeratorsList失败, %@", iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult
{
    NSLog(@"XMPPManager xmppRoom获取到BanList成功, %@", iqResult);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError
{
    NSLog(@"XMPPManager xmppRoom获取到BanList成功, %@", iqError);
}





/////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
/////////////////////////////////////////////////////////////////////////////////////


- (NSManagedObjectContext *) managedObjectContext_roster
{
    return [_xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *) managedObjectContext_capabilities
{
    return [_xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_messageArchiving
{
    return [_xmppMessageArchivingCoreDataStorage mainThreadManagedObjectContext];
}


- (NSManagedObjectContext *) managedObjectContext_room
{
    return [_xmppRoomCoreDataStorage mainThreadManagedObjectContext];
}





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPMUC Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitation:(XMPPMessage *)message
{
    NSLog(@"XMPPManager XMPPMUC Delegate 接收群组:%@到邀请:%@...", roomJID, message);
    
}


- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitationDecline:(XMPPMessage *)message
{
    NSLog(@"XMPPManager XMPPMUC Delegate 接收群组:%@到邀请拒绝:%@...", roomJID, message);
    
}




@end
