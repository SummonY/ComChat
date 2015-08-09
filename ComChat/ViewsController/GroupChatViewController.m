//
//  GroupChatViewController.m
//  ComChat
//
//  Created by D404 on 15/7/10.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "GroupChatViewController.h"
#import "ChatSendBar.h"
#import "AudioView.h"
#import "EmotionView.h"
#import "ChatShareMoreView.h"
#import "UIViewAdditions.h"
#import <ReactiveCocoa.h>
#import "RoomProfileViewController.h"
#import "UserDetailViewController.h"
#import "MessageCellFactory.h"
#import <AVFoundation/AVFoundation.h>
#import "XMPPManager.h"
#import "XMPPRoomOccupantCoreDataStorageObject+RencentOccupant.h"
#import "XMPPRoomMessageCoreDataStorageObject+GroupChatMessage.h"


#define KEYBOARD_HEIGHT     216.0f

@interface ChatDateLabel : UILabel

@end

@implementation ChatDateLabel

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {4.f, 4.f, 4.f, 4.f};
    return[super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end


static XMPPJID *currentGroupJid = nil;


@interface GroupChatViewController ()<UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) NSString *groupName;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) ChatSendBar *chatSendBar;
@property (nonatomic, strong) AudioView *audioView;
@property (nonatomic, strong) EmotionView *emotionView;
@property (nonatomic, strong) ChatShareMoreView *chatShareMoreView;

@property (nonatomic, assign) BOOL willShowEmtionOrShareMoreView;
@property (nonatomic, strong) XMPPRoomMessageCoreDataStorageObject *roomContact;


@end

@implementation GroupChatViewController


#pragma mark 获取当前群组ID
+ (XMPPJID *)currentGroupJid
{
    return currentGroupJid;
}

+ (void)setCurrentGroupJid:(XMPPJID *)jid
{
    currentGroupJid = jid;
}


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 获取当期联系人，清空未读消息
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RESET_CURRENT_ROOM_UNREAD_MESSAGES_COUNT" object:self.groupChatViewModel.groupJID userInfo:nil];
    [GroupChatViewController setCurrentGroupJid:nil];
}


#pragma mark 初始化群组信息
- (instancetype)initWithGroupJID:(XMPPJID *)groupJID groupName:(NSString *)groupName
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        [GroupChatViewController setCurrentGroupJid:groupJID];
        
        self.title = groupName;
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"group_header_info"] style:UIBarButtonItemStylePlain target:self action:@selector(groupChatSet)] animated:YES];
        
        self.groupName = groupName;
        self.hidesBottomBarWhenPushed = YES;
        
        self.groupChatViewModel = [[GroupChatViewModel alloc] initWithModel:[[XMPPManager sharedManager] managedObjectContext_room]];
        self.groupChatViewModel.groupJID = [GroupChatViewController currentGroupJid];
        
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        @weakify(self)
        [self.groupChatViewModel.fetchRoomLaterSignal subscribeNext:^(id x) {
            @strongify(self)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                if ([self isNearbyBottom]) {
                    [self scrollToBottomAnimated:YES];
                }
            });
        }];
        
        [self.groupChatViewModel.fetchRoomEarlierSignal subscribeNext:^(NSIndexPath *indexPath) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                if (indexPath) {
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
                else {
                    [self scrollToBottomAnimated:YES];
                }
            });
        }];
    }
    return self;
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerKeyboardNotifications];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /* 初始化发送条框架 */
    self.chatSendBar = [[ChatSendBar alloc] initWithFunctionOptions:ChatSendBarFunctionOption_Emotion | ChatSendBarFunctionOption_More | ChatSendBarFunctionOption_Text | ChatSendBarFunctionOption_Voice];
    self.chatSendBar.delegate = self;
    self.chatSendBar.backgroundColor = [UIColor lightTextColor];
    self.chatSendBar.bottom = self.view.height;
    
    /* 初始化tableview */
    CGFloat tableViewHeight = [self getTableViewHeight];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, tableViewHeight) style:UITableViewStyleGrouped];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 10.f;
    self.tableView.sectionFooterHeight = 0.f;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.chatSendBar];
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchRoomEarlierMessageAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    /* 添加动态手势 */
    UITapGestureRecognizer *tapGestrure = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHideKeyboardAction)];
    [self.tableView addGestureRecognizer:tapGestrure];
    
    [self.groupChatViewModel fetchRoomEarlierMessage];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark 注册通知
- (void)registerKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}



#pragma mark 群组聊天设置
- (void)groupChatSet
{
    NSLog(@"群组聊天设置...");
    RoomProfileViewController *roomProfileViewController = [[RoomProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [roomProfileViewController initWithRoomJID:[GroupChatViewController currentGroupJid]];
    [self.navigationController pushViewController:roomProfileViewController animated:YES];
}



////////////////////////////////////////////////////////////////////////
#pragma mark - UIKeyboardNotification
////////////////////////////////////////////////////////////////////////

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    UIViewAnimationCurve animationCurve = [[info valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[info valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardBounds = [(NSValue *)[info objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [UIView setAnimationCurve:animationCurve];
        
        self.chatSendBar.bottom = self.view.height - keyboardBounds.size.height;
        self.tableView.height = self.chatSendBar.top;
        self.audioView.top =
        self.emotionView.top =
        self.chatShareMoreView.top = self.chatSendBar.bottom;
    } completion:^(BOOL finished) {
        [self scrollToBottomAnimated:YES];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    //[self popdownSendBarAnimation];
    
    // 键盘切换表情，消失键盘时，不需要执行下面的动画
    if (self.willShowEmtionOrShareMoreView) {
        return;
    }
    
    NSDictionary* info = [notification userInfo];
    UIViewAnimationCurve animationCurve = [[info valueForKey: UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval animationDuration = [[info valueForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        [UIView setAnimationCurve:animationCurve];
        
        self.chatSendBar.bottom = self.view.height;
        self.tableView.height = self.chatSendBar.top;
        self.audioView.top =
        self.emotionView.top =
        self.chatShareMoreView.top = self.chatSendBar.bottom;
        //self.tableView.bottom = self.chatSendBar.bottom - self.chatSendBar.height;
    } completion:^(BOOL finished) {
        
    }];
}



#pragma mark 隐藏键盘
- (void)tapHideKeyboardAction
{
    NSLog(@"点击空白隐藏键盘");
    if ([self.chatSendBar makeTextViewResignFirstResponder]) {
        
    }
    else {
        [self popdownSendBarAnimation];
    }
}

#pragma mark 是否接近底部
- (BOOL)isNearbyBottom
{
    CGFloat delta = 200.f;
    return self.tableView.contentOffset.y + delta > self.tableView.contentSize.height - self.tableView.height;
}

#pragma mark 获取TableView高度 = 屏幕高度 - statusBar高度20 - 工具条高度44 - sendBar高度
- (CGFloat)getTableViewHeight
{
    return [UIScreen mainScreen].bounds.size.height - 20.f - 44.f - self.chatSendBar.height;
}


#pragma mark 刷新获取历史信息
- (void)fetchRoomEarlierMessageAction
{
    [self.groupChatViewModel fetchRoomEarlierMessage];
    [self.refreshControl endRefreshing];
}


#pragma mark 显示用户详细信息
- (void)showUserDetail:(BOOL)isOutgoing
{
    NSString *userName;
    
    if (isOutgoing) {
        userName = [self getUserName:[XMPPManager sharedManager].myJID.bare];
    }
    else {
        //userName = [self getUserName:[NSString stringWithFormat:@"%@", [ChatViewController currentBuddyJid]]];
    }
    UserDetailViewController *userDetailViewController = [[UserDetailViewController alloc] initWithUser:userName];
    [self.navigationController pushViewController:userDetailViewController animated:YES];
}

#pragma mark 获取用户名称
- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}


//////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewDataSource
//////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.groupChatViewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.groupChatViewModel numberOfItemsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *messageUnknownCellIdentifier = @"MessageUnknownCell";
    static NSString *messageTextCellIdentifier = @"MessageTextCell";
    static NSString *messageImageCellIdentifier = @"MessageImageCell";
    static NSString *messageVoiceCellIdentifier = @"MessageVoiceCell";
    static NSString *messageAudioCellIdentifier = @"MessageAudioCell";
    static NSString *messageVideoCellIdentifier = @"MessageVideoCell";
    
    XMPPRoomMessageCoreDataStorageObject *coreDataMessage = [self.groupChatViewModel objectAtIndexPath:indexPath];
    id message = coreDataMessage.chatMessage;
    
    MessageBaseCell *cell = nil;
    
    if ([message isKindOfClass:[ChatMessageTextEntity class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:messageTextCellIdentifier];
        if (!cell) {
            cell = [[MessageTextCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageTextCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell shouldUpdateCellWithObject:message];
    }
    else if ([message isKindOfClass:[ChatMessageImageEntity class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:messageImageCellIdentifier];
        if (!cell) {
            cell = [[MessageImageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageImageCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell shouldUpdateCellWithObject:message];
    }
    else if ([message isKindOfClass:[ChatMessageVoiceEntity class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:messageVoiceCellIdentifier];
        if (!cell) {
            cell = [[MessageVoiceCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageVoiceCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell shouldUpdateCellWithObject:message];
    }
    else if ([message isKindOfClass:[ChatMessageAudioEntity class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:messageAudioCellIdentifier];
        if (!cell) {
            cell = [[MessageAudioCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageVoiceCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell shouldUpdateCellWithObject:message];
    }
    else if ([message isKindOfClass:[ChatMessageVideoEntity class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:messageVideoCellIdentifier];
        if (!cell) {
            cell = [[MessageVideoCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageVoiceCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell shouldUpdateCellWithObject:message];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:messageUnknownCellIdentifier];
        if (!cell) {
            cell = [[MessageBaseCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:messageUnknownCellIdentifier];
        }
    }
    cell.delegate = self;
    return cell;
}

////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITabelViewDelegate
////////////////////////////////////////////////////////////////////////////////////


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPRoomMessageCoreDataStorageObject *coreDataMessage = [self.groupChatViewModel objectAtIndexPath:indexPath];
    id message = coreDataMessage.chatMessage;
    
    if ([message isKindOfClass:[ChatMessageTextEntity class]]) {
        return [MessageTextCell heightForObject:message atIndexPath:indexPath tableView:tableView];
    }
    else if ([message isKindOfClass:[ChatMessageImageEntity class]]) {
        return [MessageImageCell heightForObject:message atIndexPath:indexPath tableView:tableView];
    }
    else if ([message isKindOfClass:[ChatMessageVoiceEntity class]]) {
        return [MessageVoiceCell heightForObject:message atIndexPath:indexPath tableView:tableView];
    }
    else if ([message isKindOfClass:[ChatMessageAudioEntity class]]) {
        return [MessageAudioCell heightForObject:message atIndexPath:indexPath tableView:tableView];
    }
    else if ([message isKindOfClass:[ChatMessageVideoEntity class]]) {
        return [MessageVideoCell heightForObject:message atIndexPath:indexPath tableView:tableView];
    }
    else
        return 50.f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24.f;
}

#pragma mark 每个消息显示时间
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.width, 24.f)];
    ChatDateLabel *dateTextView = [[ChatDateLabel alloc] initWithFrame:CGRectZero];
    dateTextView.textColor = [UIColor whiteColor];
    dateTextView.font = [UIFont systemFontOfSize:13.f];
    dateTextView.backgroundColor = [UIColor lightGrayColor];
    dateTextView.layer.cornerRadius = 4.f;
    dateTextView.layer.masksToBounds = YES;
    [bgView addSubview:dateTextView];
    
    NSString *title = [self.groupChatViewModel titleForHeaderInSection:section];
    dateTextView.text = title;
    [dateTextView sizeToFit];
    dateTextView.width = dateTextView.width + 4 * 2;        // 双倍边界
    dateTextView.center = CGPointMake(tableView.width / 2, bgView.height / 2);
    
    return bgView;
}


////////////////////////////////////////////////////////////////////////////////////
#pragma mark Animation
////////////////////////////////////////////////////////////////////////////////////

#pragma mark 发送条下降动画
- (void)popdownSendBarAnimation
{
    [UIView animateWithDuration:.3f animations:^{
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark 升起表情View或分享更多view
- (void)popupEmotionViewOrShareMoreViewAnimation
{
    NSLog(@"升起表情或分享更多视图...");
    self.willShowEmtionOrShareMoreView = YES;
    self.audioView.top =
    self.emotionView.top =
    self.chatShareMoreView.top = self.chatSendBar.bottom;
    
    [UIView animateWithDuration:.2f animations:^{
        self.audioView.top =
        self.emotionView.top =
        self.chatShareMoreView.top = self.view.height - self.emotionView.height;
        self.chatSendBar.bottom = self.emotionView.top;
        self.tableView.height = self.chatSendBar.top;
    } completion:^(BOOL finished) {
        
        self.willShowEmtionOrShareMoreView = NO;
        [self scrollToBottomAnimated:YES];
    }];
}

#pragma mark 下降表情或分享更多视图动画
- (void)popdownEmotionViewOrShareMoreViewAnimation
{
    NSLog(@"降下表情视图动画...");
    [UIView animateWithDuration:.2f animations:^{
        self.audioView.top =
        self.emotionView.top =
        self.chatShareMoreView.top = self.view.height;
    } completion:^(BOOL finished) {
    }];
}

#pragma mark 升起声音视图
- (void)popupaudioRecordViewAnimation
{
    NSLog(@"升起声音记录视图动画...");
    if (self.chatShareMoreView && self.emotionView) {
        [self.view bringSubviewToFront:self.audioView];
    }
    [self popupEmotionViewOrShareMoreViewAnimation];
}

#pragma mark 下降声音记录视图
- (void)popdownaudioRecordViewAnimation
{
    NSLog(@"降下音频记录视图动画...");
    [self popdownEmotionViewOrShareMoreViewAnimation];
}

#pragma mark 升起表情视图动画
- (void)popupEmotionViewAnimation
{
    NSLog(@"升起表情视图动画...");
    if (self.audioView && self.chatShareMoreView) {
        [self.view bringSubviewToFront:self.emotionView];
    }
    [self popupEmotionViewOrShareMoreViewAnimation];
}

- (void)popdownEmotionViewAnimation
{
    NSLog(@"降下表情View动画...");
    [self popdownEmotionViewOrShareMoreViewAnimation];
}

- (void)popupShareMoreViewAnimation
{
    NSLog(@"升起分享更多View动画...");
    if (self.emotionView && self.chatShareMoreView) {
        [self.view bringSubviewToFront:self.chatShareMoreView];
    }
    [self.view bringSubviewToFront:self.chatShareMoreView];
    [self popupEmotionViewOrShareMoreViewAnimation];
}

- (void)popdownShareMoreViewAnimation
{
    NSLog(@"降下分享更多视图动画...");
    [self popdownEmotionViewOrShareMoreViewAnimation];
}

#pragma mark 划动到最后一行
- (void)scrollToLastRow
{
    [self.tableView scrollToRowAtIndexPath:
     [NSIndexPath indexPathForRow:[self.groupChatViewModel numberOfItemsInSection:0] inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


#pragma mark 滚动条滚动到底部动画
- (void)scrollToBottomAnimated:(BOOL)animated
{
    [self.tableView scrollRectToVisible:CGRectMake(0.f, self.tableView.contentSize.height - self.tableView.frame.size.height, self.tableView.frame.size.width, self.tableView.frame.size.height) animated:animated];
}


- (void)scrollToTopAnimated:(BOOL)animated
{
    [self.tableView scrollRectToVisible:CGRectMake(0.f, 0.f,
                                                   self.tableView.width, self.tableView.height) animated:animated];
}




/////////////////////////////////////////////////////////////////////////////
#pragma mark SendBarDelegate
/////////////////////////////////////////////////////////////////////////////

#pragma mark 发送文本消息
- (void)sendPlainMessage:(NSString *)plainMessage
{
    NSLog(@"发送文本消息给群组...");
    [self.groupChatViewModel sendMessageWithText:plainMessage];
}

#pragma mark 显示表情View
- (void)showEmotionView
{
    NSLog(@"显示表情View");
    [self popupEmotionViewAnimation];
}

#pragma mark 显示声音View
- (void)showVoiceView
{
    NSLog(@"显示声音View");
    [self popupaudioRecordViewAnimation];
}

#pragma mark 显示键盘
- (void)showKeyboard
{
    NSLog(@"显示键盘View");
}

#pragma mark 显示分享更多View
- (void)showShareMoreView
{
    NSLog(@"显示分享更多View");
    [self popupShareMoreViewAnimation];
}


- (void)didChangeHeight:(CGFloat)height
{
    [UIView animateWithDuration:.2f animations:^{
        self.tableView.height = self.chatSendBar.top;
    } completion:^(BOOL finished) {
        //        [self scrollToBottomAnimated:NO];
    }];
}




///////////////////////////////////////////////////////////////////////////////
#pragma mark - UI Create
///////////////////////////////////////////////////////////////////////////////

#pragma mark 创建声音视图
- (AudioView *)audioView
{
    if (!_audioView) {
        _audioView = [[AudioView alloc] initWithFrame:
                      CGRectMake(0.f, self.view.height, self.view.width, KEYBOARD_HEIGHT)];
        _audioView.delegate = self;
        [self.view addSubview:_audioView];
    }
    return _audioView;
}

#pragma mark 创建表情视图
- (EmotionView *)emotionView
{
    if (!_emotionView) {
        _emotionView = [[EmotionView alloc] initWithFrame:
                        CGRectMake(0.f, self.view.height, self.view.width, KEYBOARD_HEIGHT)];
        _emotionView.emotionDelegate = self;
        [self.view addSubview:_emotionView];
    }
    return _emotionView;
}

#pragma mark 创建分享更多视图
- (ChatShareMoreView *)chatShareMoreView
{
    if (!_chatShareMoreView) {
        _chatShareMoreView = [[ChatShareMoreView alloc] initWithFrame:
                              CGRectMake(0.f, self.view.height, self.view.width, KEYBOARD_HEIGHT)];
        _chatShareMoreView.chatShareMoreDelegate = self;
        [self.view addSubview:_chatShareMoreView];
    }
    return _chatShareMoreView;
}



///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Emotion Delegate
//////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)emotionSelectedWithName:(NSString*)name
{
    [self.chatSendBar insertEmotionName:name];
}

- (void)didEmotionViewDeleteAction
{
    [self.chatSendBar deleteLastCharTextView];
}

- (void)didEmotionViewSendAction
{
    [self.groupChatViewModel sendMessageWithText:self.chatSendBar.inputText];
}


//////////////////////////////////////////////////////////////////////////////////
#pragma mark - IMaudioRecordView Delegate
//////////////////////////////////////////////////////////////////////////////////

#pragma mark 完成语音记录并发送URL
- (void)didFinishRecordingAudioWithUrlKey:(NSString *)voiceName data:(NSData *)voiceData time:(NSInteger)time
{
    NSLog(@"完成语音记录,发送...");
    // 发送图片
    [self.groupChatViewModel sendMessageWithAudioTime:time data:voiceData urlkey:voiceName];
}



//////////////////////////////////////////////////////////////////
#pragma mark - ChatMoreViewDelegate
//////////////////////////////////////////////////////////////////

#pragma 从相册获取照片
- (void)didPickPhotoFromLibrary
{
    NSLog(@"打开相册选择照片上传图片...");
    
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.allowsEditing = YES;
    imagePickerController.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:NULL];
    
}

#pragma 相机拍摄照片
- (void)didPickPhotoFromCamera
{
    NSLog(@"选择相机拍摄并上传图片...");
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertView *alertCamera = [[UIAlertView alloc] initWithTitle:@"相机功能不可用" message:@"无法拍摄照片，请先在设置中为该软件授权相机服务，然后重试！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertCamera show];
        return ;
    }
    
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"相机不可用" message:@"摄像头不可用, 无法拍摄照片，请检查重试！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:^{}];
}

#pragma mark 选择文件
- (void)didPickFileFromDocument
{
    NSLog(@"选择文件上传...");
    /*
     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
     
     NSLog(@"文档目录%@", [paths lastObject]);
     
     NSURL *url = [[NSBundle mainBundle] URLForResource:@"" withExtension:@"*.*"];
     if (url) {
     UIDocumentInteractionController *documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
     documentController.delegate = self;
     [documentController presentOpenInMenuFromRect:[[UIButton alloc] frame] inView:self.view animated:YES];
     }
     */
}

/*
 #pragma mark 点击拨打电话
 - (void)didClickedAudio
 {
 NSLog(@"向对方发起电话邀请...");
 RTCAudioChatViewController *rtcAudioChatViewController = [[RTCAudioChatViewController alloc] init];
 [self.navigationController pushViewController:rtcAudioChatViewController animated:YES];
 }
 
 
 #pragma mark 点击开始视频
 - (void)didClickedVideo
 {
 NSLog(@"向对方发起视频邀请...");
 RTCVideoChatViewController *rtcVideoChatViewController = [[RTCVideoChatViewController alloc] initWithUserJid:[ChatViewController currentBuddyJid].bare];
 [self.navigationController pushViewController:rtcVideoChatViewController animated:YES];
 }
 */


#pragma mark 从相机或相册获取照片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    NSLog(@"获取并发送图片...");
    // 发送图片
    [self.groupChatViewModel sendMessageWithImage:image];       // 群聊
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark 取消选择照片
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"取消选择图片");
    [picker dismissViewControllerAnimated:YES completion:^{}];
}



//////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollView Delegate
//////////////////////////////////////////////////////////////////////////////////////


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.chatSendBar makeTextViewResignFirstResponder]) {
        // 当前显示键盘，退出键盘
    }
    else {
        [self popdownSendBarAnimation];
    }
}



///////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
///////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"GroupChatViewController 发送消息成功");
    
    NSString *roomBare = [[message attributeForName:@"to"] stringValue];
    XMPPJID *roomJid = [XMPPJID jidWithString:roomBare];
    
    if ([self.groupChatViewModel.groupJID isEqualToJID:roomJid options:XMPPJIDCompareBare]) {
        [self.chatSendBar clearInputTextView];
        [self.chatSendBar makeSendEnable];
    }
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    NSLog(@"GroupChatViewController 消息发送失败, %@", error);
    
    NSString *roomBar = [[message attributeForName:@"to"] stringValue];
    if ([self.groupChatViewModel.groupJID.full isEqualToString:roomBar]) {
        [self.chatSendBar makeSendEnable];
    }
}

@end
