//
//  MessageCellFactory.m
//  ComChat
//
//  Created by D404 on 15/6/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "MessageCellFactory.h"
#import "ChatMessageEntityFactory.h"
#import <Nimbus/NIAttributedLabel.h>
#import "UIViewAdditions.h"
#import "ParserKeyword.h"
#import <UIImageView+WebCache.h>
#import "ChatViewController.h"
#import <ReactiveCocoa.h>
#import <MBProgressHUD.h>
#import "UIImage+Utils.h"
#import "JLFullScreenPhotoBrowseView.h"
#import "UIView+findViewController.h"
#import <UIImageView+AFNetworking.h>
#import <ASIHTTPRequest.h>
#import "ResourceManager.h"


@implementation MessageCellFactory


@end


//////////////////////////////////////////////////////////////////////////
#pragma mark MessageBaseCell
//////////////////////////////////////////////////////////////////////////

@interface MessageBaseCell()

@property (nonatomic, strong) UIButton *headView;
@property (nonatomic, strong) UIImageView *bubbleBgView;
@property (nonatomic, assign) ChatMessageType type;
@property (nonatomic, assign) BOOL isOutgoing;          // 发送YES、接受NO

@end

@implementation MessageBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 头像
        self.headView = [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, 40.f, 40.f)];
        [self.headView setImage:[UIImage imageNamed:@"user_head_default"] forState:UIControlStateNormal];
        [self.headView addTarget:self action:@selector(showUserInfo:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.headView];
        
        
        self.bubbleBgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.bubbleBgView.userInteractionEnabled = YES;
        [self.contentView addSubview:self.bubbleBgView];
        
        // 添加长按手势识别
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenuView)];
        [self.bubbleBgView addGestureRecognizer:longGesture];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] init];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

#pragma mark 重用
- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.headView setImage:[UIImage imageNamed:@"user_head_default"] forState:UIControlStateNormal];
}

#pragma mark 加载子视图
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, self.height);
    
    UIImage *bubbleBgImage = [self bubbleImageForMessageType:self.type
                                                  isOutgoing:self.isOutgoing];
    // 根据发送和接受不同，显示头像位置不同
    if (self.isOutgoing) {
        self.headView.right = self.contentView.width - 10;
        self.headView.top = 10;
        [self.bubbleBgView setImage:[bubbleBgImage stretchableImageWithLeftCapWidth:bubbleBgImage.size.width / 2
                                                                       topCapHeight:bubbleBgImage.size.height / 2]];
    }
    else {
        self.headView.left = 10;
        self.headView.top = 10;
        [self.bubbleBgView setImage:[bubbleBgImage stretchableImageWithLeftCapWidth:bubbleBgImage.size.width / 2
                                                                       topCapHeight:bubbleBgImage.size.height / 2]];
    }
}

#pragma mark 显示好友或自己信息
- (void)showUserInfo:(id)object
{
    NSLog(@"显示自己或好友详细信息...");
    if (self.isOutgoing) {
        NSLog(@"显示自己详细信息");
        if (self.delegate && [self.delegate respondsToSelector:@selector(showUserDetail:)]) {
            [self.delegate showUserDetail:YES];
        }
    } else {
        NSLog(@"显示好友详细信息");
        if (self.delegate && [self.delegate respondsToSelector:@selector(showUserDetail:)]) {
            [self.delegate showUserDetail:NO];
        }
    }
}

#pragma mark 更新Cell
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[ChatMessageBaseEntity class]]) {
        ChatMessageBaseEntity *entity = (ChatMessageBaseEntity *)object;
        
        // TODO
        /* 根据发送和接收设置用户头像 */
        if (entity.isOutgoing) {
            [self.headView setImage:[UIImage imageNamed:@"user_head_default"] forState:UIControlStateNormal];
        }
        else {
            if ([ChatViewController currentBuddyJid]) {
                [self.headView setImage:[UIImage imageNamed:@"user_head_default"] forState:UIControlStateNormal];
            }
        }
    }
    return YES;
}

#pragma mark 长按显示复制或删除
- (void)showMenuView
{
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"复制"
                                                      action:@selector(copyContent)];
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
    [menuController setTargetRect:CGRectInset(self.bounds, 0.f, 4.f) inView:self];
    [menuController setMenuVisible:YES animated:YES];
}

#pragma mark 长按复制操作
- (void)copyContent
{
    NSLog(@"复制消息内容...");
}


#pragma mark 消息背景图
- (UIImage *)bubbleImageForMessageType:(ChatMessageType)type isOutgoing:(BOOL)isOutgoing
{
    UIImage *bubbleBgImage = nil;
    NSString *namePrefix = isOutgoing ? @"Sender" : @"Receiver";        // 根据发送接收不同显示不同图片
    switch (type) {
        case ChatMessageType_Text:
            bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Text_bg_nor", namePrefix]];
            break;
        case ChatMessageType_Voice:
            bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Voice_bg_nor", namePrefix]];
            break;
        case ChatMessageType_Image:
            bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Image_border", namePrefix]];
            break;
        case ChatMessageType_Audio:
            bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Voice_bg_nor", namePrefix]];
            break;
        case ChatMessageType_Video:
            bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Voice_bg_nor", namePrefix]];
            break;
        default:
            break;
    }
    return bubbleBgImage;
}


@end



//////////////////////////////////////////////////////////////////////////
#pragma mark MessageTextCell
//////////////////////////////////////////////////////////////////////////

#define CONTENT_MAX_WIDTH       180
#define CONTENT_LINE_HEIGHT     20
#define BUBBLE_TOP_MARGIN       10
#define BUBBLE_BOTTOM_MARGIN    20
#define BUBBLE_ARROW_MARGIN     20

@interface MessageTextCell()<NIAttributedLabelDelegate>

@property (nonatomic, strong) NIAttributedLabel *contentLabel;
@property (nonatomic, strong) ChatMessageTextEntity *textMessage;

@end

@implementation MessageTextCell

#pragma mark 表情插入到内容中
+ (void)insertAllEmotionsInContentLabel:(NIAttributedLabel *)contentLabel withChatMessage:(ChatMessageTextEntity *)entity
{
    ParserKeyword *keywordEntity = nil;
    
    if (entity.emotionRanges.count) {
        NSString *emotionImageName = nil;
        
        NSData *imageData = nil;
        for (int i = entity.emotionRanges.count - 1; i >= 0; --i) {
            keywordEntity = (ParserKeyword *)entity.emotionRanges[i];
            
            if (i < entity.emotionImageNames.count) {
                emotionImageName = entity.emotionImageNames[i];
                
                if (emotionImageName.length) {
                    imageData = UIImagePNGRepresentation([UIImage imageNamed:emotionImageName]);
                    [contentLabel insertImage:[UIImage imageWithData:imageData scale:2.4f] atIndex:keywordEntity.range.location margins:UIEdgeInsetsZero];
                }
            }
        }
    }
}

#pragma 根据宽度获取属性高度
+ (CGFloat)attributeHeightForEntity:(ChatMessageTextEntity *)entity withWidth:(CGFloat)width
{
    static NIAttributedLabel *contentLabel = nil;
    
    if (!contentLabel) {
        contentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
        contentLabel.numberOfLines = 0;
        contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        contentLabel.font = [UIFont systemFontOfSize:16.f];
        contentLabel.lineHeight = 20;
        contentLabel.width = width;
    }
    else {
        contentLabel.frame = CGRectZero;
        contentLabel.width = width;
    }
    
    contentLabel.text = entity.text;
    [self insertAllEmotionsInContentLabel:contentLabel withChatMessage:entity];
    
    CGSize contentSize = [contentLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    if (contentSize.height < CONTENT_LINE_HEIGHT) {
        contentSize.height = CONTENT_LINE_HEIGHT;
    }
    return contentSize.height;
}


#pragma mark 自动调节TableviewCell 的高度
+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    // 内容
    if ([object isKindOfClass:[ChatMessageTextEntity class]]) {
        ChatMessageTextEntity *textEntity = (ChatMessageTextEntity *)object;
        CGFloat margin = 10.f;
        CGFloat height = margin;
        
        CGFloat kContentLength = CONTENT_MAX_WIDTH;
        
        CGFloat contentHeight = [self attributeHeightForEntity:textEntity withWidth:kContentLength];
        
        if (contentHeight < 20) {
            height = height + 40;
        } else {
            height = height + contentHeight + 10 + 20;
        }
        
        return  height;
    }
    return 0.0f;
}


#pragma mark 更新Cell对象
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    
    if ([object isKindOfClass:[ChatMessageTextEntity class]]) {
        self.textMessage = (ChatMessageTextEntity *)object;
        self.type = self.textMessage.type;
        self.isOutgoing = self.textMessage.isOutgoing;
        
        [self.textMessage parseAllKeywords];
        self.contentLabel.text = self.textMessage.text;
        [MessageTextCell insertAllEmotionsInContentLabel:self.contentLabel withChatMessage:self.textMessage];
    }
    return YES;
}

#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentLabel.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

#pragma mark 布局子视图
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 8;
    CGFloat margin = 10;
    
    // status content
    CGFloat kContentLength = CONTENT_MAX_WIDTH;
    self.contentLabel.frame = CGRectMake(0.f, self.headView.top + margin,
                                         kContentLength, 0.f);
    [self.contentLabel sizeToFit];
    if (self.contentLabel.height < CONTENT_LINE_HEIGHT) {
        self.contentLabel.height = CONTENT_LINE_HEIGHT;
    }
    self.bubbleBgView.frame = CGRectMake(self.bubbleBgView.left, self.headView.top,
                                         self.contentLabel.width + padding + 10 + BUBBLE_ARROW_MARGIN,
                                         self.contentLabel.height + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN);
    
    if (self.isOutgoing) {
        self.contentLabel.right = self.headView.left - padding - BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.right = self.headView.left - padding;
    }
    else {
        self.contentLabel.left = self.headView.right + padding + BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.left = self.headView.right + padding;
    }
}


#pragma mark 内容Label
- (NIAttributedLabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
        _contentLabel.numberOfLines = 0;
        _contentLabel.font = [UIFont systemFontOfSize:16.f];
        _contentLabel.lineHeight = CONTENT_LINE_HEIGHT;
        _contentLabel.textColor = RGBCOLOR(30, 30, 30);
        _contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _contentLabel.autoDetectLinks = YES;
        _contentLabel.delegate = self;
        _contentLabel.attributesForLinks = @{(NSString *)kCTForegroundColorAttributeName:(id)RGBCOLOR(6, 89, 155).CGColor};
        _contentLabel.highlightedLinkBackgroundColor = RGBCOLOR(26, 162, 233);
        
        [self.contentView addSubview:_contentLabel];
    }
    return _contentLabel;
}


@end


//////////////////////////////////////////////////////////////////////////
#pragma mark MessageImageCell
//////////////////////////////////////////////////////////////////////////

#define IMAGE_MAX_LENGTH 100

@interface MessageImageCell()

@property (nonatomic, strong) ChatMessageImageEntity *imageMessage;
@property (nonatomic, strong) UIImageView *contentImageView;

@end


@implementation MessageImageCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return IMAGE_MAX_LENGTH + 8 * 2 + 10;
}

#pragma mark 初始化样式
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.bubbleBgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.bubbleBgView];
        
        self.contentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.contentImageView];
        
        // 图片手势
        self.contentImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer* tapContentImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(showContentOriginImage)];
        [self.contentImageView addGestureRecognizer:tapContentImageGesture];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 8;
    
    CGSize displaySize = [[self class] displaySizeForImageSourceSize:
                          CGSizeMake(self.imageMessage.width, self.imageMessage.height)];
    self.bubbleBgView.frame = CGRectMake(self.bubbleBgView.left, self.headView.top,
                                         displaySize.width, displaySize.height);
    
    if (self.isOutgoing) {
        self.bubbleBgView.right = self.headView.left - padding;
    }
    else {
        self.bubbleBgView.left = self.headView.right + padding;
    }
    self.contentImageView.frame = self.bubbleBgView.frame;
    
    
    NSString *imageFile = [self.imageMessage.url lastPathComponent];
    NSString *imageFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    imageFilePath = [imageFilePath stringByAppendingPathComponent:imageFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 已下载从文件直接打开，未下载从网络下载后打开
    if ([fileManager fileExistsAtPath:imageFilePath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
        self.imageView.image = image;
        UIImage *maskImage = [[self class] maskImageWithSize:self.bubbleBgView.size
                                                  isOutgoing:self.isOutgoing];
        self.contentImageView.image = [image maskWithImage:maskImage];
    } else {
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.imageMessage.url]];
        [request setUsername:@"admin"];
        [request setPassword:@"admin"];
        request.delegate = self;
        [request setDownloadDestinationPath:imageFilePath];
        [request setAllowResumeForFileDownloads:YES];           // 断点续传
        [request setCompletionBlock:^{
            NSLog(@"响应数据:%@", [request responseString]);
            UIImage *image = [UIImage imageWithContentsOfFile:[request downloadDestinationPath]];
            self.imageView.image = image;
            UIImage *maskImage = [[self class] maskImageWithSize:self.bubbleBgView.size
                                                      isOutgoing:self.isOutgoing];
            self.contentImageView.image = [image maskWithImage:maskImage];
        }];
        [request setFailedBlock:^{
            NSLog(@"图片下载失败, %@", request.error);
        }];
        [request startAsynchronous];
    }
}


- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    
    if ([object isKindOfClass:[ChatMessageImageEntity class]]) {
        self.imageMessage = (ChatMessageImageEntity *)object;
        self.type = ChatMessageType_Image;
        self.isOutgoing = self.imageMessage.isOutgoing;
    }
    
    return YES;
}

#pragma mark 转向显示图片
- (void)showContentOriginImage
{
    if (self.viewController) {
        if ([self.viewController isKindOfClass:[UIViewController class]]) {
            UITableView* tableView = ((UITableViewController*)self.viewController).tableView;
            UIWindow* window = [UIApplication sharedApplication].keyWindow;
            
            // convert rect to self(cell)
            CGRect rectInCell = [self.contentView convertRect:self.contentImageView.frame toView:self];
            
            // convert rect to tableview
            CGRect rectInTableView = [self convertRect:rectInCell toView:tableView];//self.superview
            
            // convert rect to window
            CGRect rectInWindow = [tableView convertRect:rectInTableView toView:window];
            
            // 全屏显示图片
            UIImage* image = self.contentImageView.image;
            if (image) {
                rectInWindow = CGRectMake(rectInWindow.origin.x + (rectInWindow.size.width - image.size.width) / 2.f,
                                          rectInWindow.origin.y + (rectInWindow.size.height - image.size.height) / 2.f,
                                          image.size.width, image.size.height);
            }
            JLFullScreenPhotoBrowseView* browseView =
            [[JLFullScreenPhotoBrowseView alloc] initWithUrlPath:self.imageMessage.url
                                                       thumbnail:self.contentImageView.image
                                                        fromRect:rectInWindow];
            [window addSubview:browseView];
            
        }
    }
}


+ (UIImage *)maskImageWithSize:(CGSize)size isOutgoing:(BOOL)isOutgoing
{
    UIImage *maskSourceImage = [[self class] bubbleMaskImageForIsOutgoing:isOutgoing];
    UIImage *stretchImage = [maskSourceImage stretchableImageWithLeftCapWidth:maskSourceImage.size.width / 2
                                                                 topCapHeight:maskSourceImage.size.height / 2];
    UIImage *maskImage = [stretchImage renderAtSize:size];
    return maskImage;
}

+ (CGSize)displaySizeForImageSourceSize:(CGSize)sourceSize
{
    CGFloat realWidth = sourceSize.width;
    CGFloat realHeight = sourceSize.height;
    
    if (sourceSize.width > sourceSize.height) {
        if (sourceSize.width > IMAGE_MAX_LENGTH) {
            realWidth = IMAGE_MAX_LENGTH;
            realHeight =  sourceSize.height * IMAGE_MAX_LENGTH / sourceSize.width;
        }
    }
    else {
        if (sourceSize.height > IMAGE_MAX_LENGTH) {
            realHeight = IMAGE_MAX_LENGTH;
            realWidth = sourceSize.width * IMAGE_MAX_LENGTH / sourceSize.height;
        }
    }
    return CGSizeMake(realWidth, realHeight);
}


+ (UIImage *)bubbleMaskImageForIsOutgoing:(BOOL)isOutgoing
{
    UIImage *bubbleBgImage = nil;
    NSString *namePrefix = isOutgoing ? @"Sender" : @"Receiver";
    
    bubbleBgImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Image_Border_back.png", namePrefix]];
    
    return bubbleBgImage;
}



@end



//////////////////////////////////////////////////////////////////////////
#pragma mark MessageVoiceCell
//////////////////////////////////////////////////////////////////////////

#define IMAGE_VOICE_HEIGHT 20
#define PROGRESS_VIEW_LENGTH 30


@interface MessageVoiceCell()

@property (nonatomic, strong) ChatMessageVoiceEntity *audioEntity;
@property (nonatomic, strong) UIImageView *audioImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) MBRoundProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end


@implementation MessageVoiceCell


+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
{
    return CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN + 10;
}

#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.audioImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, IMAGE_VOICE_HEIGHT, IMAGE_VOICE_HEIGHT)];
        [self.contentView addSubview:self.audioImageView];
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLabel.textColor = [UIColor grayColor];
        self.timeLabel.font = [UIFont systemFontOfSize:16.f];
        [self.contentView addSubview:self.timeLabel];
        
        self.progressView = [[MBRoundProgressView alloc] initWithFrame:CGRectMake(0.f, 0.f, PROGRESS_VIEW_LENGTH, PROGRESS_VIEW_LENGTH)];
        self.progressView.userInteractionEnabled = YES;
        self.progressView.progressTintColor = [UIColor whiteColor];
        self.progressView.backgroundTintColor = RGBCOLOR(240, 240, 240);
        [self.contentView addSubview:self.progressView];
        
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:self.indicatorView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(playVoiceAction)];
        [self.bubbleBgView addGestureRecognizer:tapGesture];
    }
    return self;
}

#pragma mark 复用
- (void)prepareForReuse
{
    [super prepareForReuse];
    
    // TODO: 考虑cell复用时，如何处理音频的下载进度
}

#pragma mark 子视图布局
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 8;
    CGFloat margin = 10;
    
    CGFloat kViewMaxLength = CONTENT_MAX_WIDTH;
    CGFloat kViewMinLength = 40.f;
    CGFloat viewLengthForTime = self.audioEntity.time * 10.f + kViewMinLength;
    CGFloat viewLength = fminf(kViewMaxLength, viewLengthForTime);
    self.bubbleBgView.frame = CGRectMake(self.bubbleBgView.left, self.headView.top,
                                         viewLength + padding + 10 + BUBBLE_ARROW_MARGIN,
                                         CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN);
    [self.timeLabel sizeToFit];
    self.audioImageView.top = self.headView.top + margin;
    self.timeLabel.bottom = self.audioImageView.bottom;
    self.progressView.centerY = self.timeLabel.centerY;
    
    if (self.isOutgoing) {
        self.audioImageView.right = self.headView.left - padding - BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.right = self.headView.left - padding;
        self.timeLabel.right = self.bubbleBgView.left - 2;
        self.progressView.right = self.timeLabel.left - 4;
    }
    else {
        self.audioImageView.left = self.headView.right + padding + BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.left = self.headView.right + padding;
        self.timeLabel.left = self.bubbleBgView.right + 2;
        self.progressView.left = self.timeLabel.right + 4;
    }
    
    self.indicatorView.frame = self.progressView.frame;
    self.progressView.hidden = YES;
    self.audioImageView.image = [MessageVoiceCell voiceImageForIsOutgoing:self.isOutgoing];
}

#pragma mark 更新Cell
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    
    if ([object isKindOfClass:[ChatMessageVoiceEntity class]]) {
        self.audioEntity = (ChatMessageVoiceEntity *)object;
        self.timeLabel.text = [NSString stringWithFormat:@"%d''", self.audioEntity.time];
        self.isOutgoing = self.audioEntity.isOutgoing;
    }
    return YES;
}

#pragma mark 设置声音背景图片
+ (UIImage *)voiceImageForIsOutgoing:(BOOL)isOutgoing
{
    UIImage *image = nil;
    NSString *namePrefix = isOutgoing ? @"Sender" : @"Receiver";
    
    image = [UIImage imageNamed:[NSString stringWithFormat:@"%@_Voice_Playing", namePrefix]];
    
    return image;
}

#pragma mark 播放音频
- (void)playVoiceAction
{
    NSString *voiceFile = [self.audioEntity.url lastPathComponent];
    NSString *voiceFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    voiceFilePath = [voiceFilePath stringByAppendingPathComponent:voiceFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:voiceFilePath]) {         // 若文件已经存在则直接从本地读取
        // amr格式转换为WAV格式
        
        
        [self.indicatorView startAnimating];
        @weakify(self);
        [self.audioEntity playAudioWithProgressBlock:^(CGFloat progress) {
            @strongify(self);
            self.progressView.progress = progress;
            self.progressView.hidden = (progress < 1.0) ? NO : YES;
            if (progress > 0.f && !self.indicatorView.hidden) {
                [self.indicatorView stopAnimating];
                self.indicatorView.hidden = YES;
            }
        }];
    } else {            // 若文件不存在，则根据URL从网络下载
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.audioEntity.url]];
        [request setUsername:@"admin"];
        [request setPassword:@"admin"];
        request.delegate = self;
        [request setDownloadDestinationPath:voiceFilePath];
        [request setAllowResumeForFileDownloads:YES];   // 断点续传
        [request setCompletionBlock:^{
            NSLog(@"响应数据:%@", [request responseString]);
            
            [self.indicatorView startAnimating];
            @weakify(self);
            [self.audioEntity playAudioWithProgressBlock:^(CGFloat progress) {
                @strongify(self);
                self.progressView.progress = progress;
                self.progressView.hidden = (progress < 1.0) ? NO : YES;
                if (progress > 0.f && !self.indicatorView.hidden) {
                    [self.indicatorView stopAnimating];
                    self.indicatorView.hidden = YES;
                }
            }];
        }];
        
        [request setFailedBlock:^{
            NSLog(@"音频下载失败, %@", [request.error description]);
        }];
        [request startAsynchronous];
    }
}


@end




////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark MessageAudioCell
////////////////////////////////////////////////////////////////////////////////////////////

@interface MessageAudioCell()

@property (nonatomic, strong) ChatMessageAudioEntity *audioEntity;
@property (nonatomic, strong) UIImageView *audioImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NIAttributedLabel *contentLabel;

@end


@implementation MessageAudioCell

#pragma mark Audio Cell高度
+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN + 10;
}

#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.audioImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, IMAGE_VOICE_HEIGHT, IMAGE_VOICE_HEIGHT)];
        [self.contentView addSubview:self.audioImageView];
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLabel.textColor = [UIColor grayColor];
        self.timeLabel.font = [UIFont systemFontOfSize:16.f];
        [self.contentView addSubview:self.timeLabel];
        
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(playVoiceAction)];
        [self.bubbleBgView addGestureRecognizer:tapGesture];
    }
    return self;
}


#pragma mark 子视图布局
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 8;
    CGFloat margin = 10;
    
    CGFloat kViewMaxLength = CONTENT_MAX_WIDTH;
    CGFloat kViewMinLength = 40.f;
    CGFloat viewLengthForTime = self.audioEntity.time * 10.f + kViewMinLength;
    CGFloat viewLength = fminf(kViewMaxLength, viewLengthForTime);
    self.bubbleBgView.frame = CGRectMake(self.bubbleBgView.left, self.headView.top,
                                         viewLength + padding + 10 + BUBBLE_ARROW_MARGIN,
                                         CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN);
    [self.timeLabel sizeToFit];
    self.audioImageView.top = self.headView.top + margin;
    self.timeLabel.bottom = self.audioImageView.bottom;
    
    if (self.isOutgoing) {
        self.audioImageView.right = self.headView.left - padding - BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.right = self.headView.left - padding;
        self.timeLabel.right = self.bubbleBgView.left - 2;
    }
    else {
        self.audioImageView.left = self.headView.right + padding + BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.left = self.headView.right + padding;
        self.timeLabel.left = self.bubbleBgView.right + 2;
    }
    
    self.audioImageView.image = [UIImage imageNamed:@"chat_content_audio_call"];
}


#pragma mark 更新Cell对象
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    
    if ([object isKindOfClass:[ChatMessageAudioEntity class]]) {
        self.audioEntity = (ChatMessageAudioEntity *)object;
        self.type = self.audioEntity.type;
        self.isOutgoing = self.audioEntity.isOutgoing;
        
        if (self.isOutgoing) {
            self.contentLabel.text = @"已取消";
        }
        else {
            self.contentLabel.text = @"未接听";
        }
    }
    return YES;
}



@end




////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark MessageVideoCell
////////////////////////////////////////////////////////////////////////////////////////////

@interface MessageVideoCell()

@property (nonatomic, strong) ChatMessageVideoEntity *videoEntity;
@property (nonatomic, strong) UIImageView *videoImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NIAttributedLabel *contentLabel;

@end


@implementation MessageVideoCell

#pragma mark Video Cell高度
+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN + 10;
}

#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.videoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, IMAGE_VOICE_HEIGHT, IMAGE_VOICE_HEIGHT)];
        [self.contentView addSubview:self.videoImageView];
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLabel.textColor = [UIColor grayColor];
        self.timeLabel.font = [UIFont systemFontOfSize:16.f];
        [self.contentView addSubview:self.timeLabel];
        
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(playVoiceAction)];
        [self.bubbleBgView addGestureRecognizer:tapGesture];
    }
    return self;
}


#pragma mark 子视图布局
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 8;
    CGFloat margin = 10;
    
    CGFloat kViewMaxLength = CONTENT_MAX_WIDTH;
    CGFloat kViewMinLength = 40.f;
    CGFloat viewLengthForTime = self.videoEntity.time * 10.f + kViewMinLength;
    CGFloat viewLength = fminf(kViewMaxLength, viewLengthForTime);
    self.bubbleBgView.frame = CGRectMake(self.bubbleBgView.left, self.headView.top,
                                         viewLength + padding + 10 + BUBBLE_ARROW_MARGIN,
                                         CONTENT_LINE_HEIGHT + BUBBLE_TOP_MARGIN + BUBBLE_BOTTOM_MARGIN);
    [self.timeLabel sizeToFit];
    self.videoImageView.top = self.headView.top + margin;
    self.timeLabel.bottom = self.videoImageView.bottom;
    
    if (self.isOutgoing) {
        self.videoImageView.right = self.headView.left - padding - BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.right = self.headView.left - padding;
        self.timeLabel.right = self.bubbleBgView.left - 2;
    }
    else {
        self.videoImageView.left = self.headView.right + padding + BUBBLE_ARROW_MARGIN;
        self.bubbleBgView.left = self.headView.right + padding;
        self.timeLabel.left = self.bubbleBgView.right + 2;
    }
    
    self.videoImageView.image = [UIImage imageNamed:@"chat_content_video_call"];
}


#pragma mark 更新Cell对象
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    
    if ([object isKindOfClass:[ChatMessageAudioEntity class]]) {
        self.videoEntity = (ChatMessageVideoEntity *)object;
        self.type = self.videoEntity.type;
        self.isOutgoing = self.videoEntity.isOutgoing;
        
        if (self.isOutgoing) {
            self.contentLabel.text = @"已取消";
        }
        else {
            self.contentLabel.text = @"未接听";
        }
    }
    return YES;
}

@end






