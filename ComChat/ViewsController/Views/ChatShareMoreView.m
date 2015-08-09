//
//  ChatMoreView.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ChatShareMoreView.h"

#define PAGE_MAX_COUNT          6
#define LAUNCHER_BUTTON_WIDTH   64
#define LAUNCHER_LABEL_HEIGHT   15
#define NUMBER_OF_ROWS          2
#define NUMBER_OF_COLUMNS       3


@interface ChatShareButtonView : NILauncherButtonView

@end


@implementation ChatShareButtonView


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithReuseIdentifier:reuseIdentifier])) {
        
        [self.button setBackgroundImage:[UIImage imageNamed:@"sharemore_bg"]
                               forState:UIControlStateNormal];
        [self.button setBackgroundImage:[UIImage imageNamed:@"sharemore_bg_HL"]
                               forState:UIControlStateHighlighted];
        self.backgroundColor = [UIColor clearColor];
        self.button.backgroundColor = [UIColor clearColor];
        self.label.backgroundColor = [UIColor clearColor];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.label.font = [UIFont systemFontOfSize:12.f];
    self.label.textColor = [UIColor darkGrayColor];
    
    //    CGFloat kSeperateSpace = 10.f;
    //    self.label.top = self.label.top + kSeperateSpace;
    
    self.button.frame = CGRectMake(0.f, 0.f, LAUNCHER_BUTTON_WIDTH, LAUNCHER_BUTTON_WIDTH);
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - IMChatShareButtonObject
///////////////////////////////////////////////////////////////////////////////////////////////////

@interface ChatShareButtonObject : NILauncherViewObject

@end

@implementation ChatShareButtonObject

- (Class)buttonViewClass
{
    return [ChatShareButtonView class];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - IMChatShareMoreView
///////////////////////////////////////////////////////////////////////////////////////////////////

@interface ChatShareMoreView()<NILauncherViewModelDelegate, NILauncherDelegate>

@property (nonatomic, readwrite, retain) NILauncherViewModel* model;

@end

@implementation ChatShareMoreView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSMutableArray *itemPages = [NSMutableArray arrayWithCapacity:2];
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:10];
        
        NILauncherViewObject *item = nil;
        item = [[ChatShareButtonObject alloc] initWithTitle:@"照片"
                                                        image:[UIImage imageNamed:@"sharemore_photo"]];
        [items addObject:item];
        
        item = [[ChatShareButtonObject alloc] initWithTitle:@"拍摄"
                                                        image:[UIImage imageNamed:@"sharemore_camera"]];
        [items addObject:item];
        
        item = [[ChatShareButtonObject alloc] initWithTitle:@"文件"
                                                        image:[UIImage imageNamed:@"sharemore_file"]];
        [items addObject:item];
        
        item = [[ChatShareButtonObject alloc] initWithTitle:@"电话"
                                                      image:[UIImage imageNamed:@"sharemore_audio"]];
        [items addObject:item];
        
        item = [[ChatShareButtonObject alloc] initWithTitle:@"视频"
                                                      image:[UIImage imageNamed:@"sharemore_video"]];
        [items addObject:item];

        [itemPages addObject:items];
        
        self.backgroundColor = RGBCOLOR(244, 244, 244);
        self.contentInsetForPages = UIEdgeInsetsMake(10.f, 0.f, 0.f, 0.f);
        self.buttonSize = CGSizeMake(LAUNCHER_BUTTON_WIDTH, LAUNCHER_BUTTON_WIDTH + LAUNCHER_LABEL_HEIGHT);
        self.numberOfRows = NUMBER_OF_ROWS;
        self.numberOfColumns = NUMBER_OF_COLUMNS;
        _model = [[NILauncherViewModel alloc] initWithArrayOfPages:itemPages delegate:self];
        self.dataSource = self.model;
        self.delegate = self;
        [self reloadData];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NILauncherViewModelDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)launcherViewModel:(NILauncherViewModel *)launcherViewModel
      configureButtonView:(UIView<NILauncherButtonView> *)buttonView
          forLauncherView:(NILauncherView *)launcherView
                pageIndex:(NSInteger)pageIndex
              buttonIndex:(NSInteger)buttonIndex
                   object:(id<NILauncherViewObject>)object
{
    
    NILauncherButtonView* launcherButtonView = (NILauncherButtonView *)buttonView;
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NILauncherDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)launcherView:(NILauncherView *)launcherView
 didSelectItemOnPage:(NSInteger)page
             atIndex:(NSInteger)index
{
    NSInteger realIndex = PAGE_MAX_COUNT * page + index;
    switch (realIndex) {
        case 0:
        {
            // 图片
            if (self.chatShareMoreDelegate && [self.chatShareMoreDelegate respondsToSelector:@selector(didPickPhotoFromLibrary)]) {
                [self.chatShareMoreDelegate didPickPhotoFromLibrary];
            }
            break;
        }
        case 1:
        {
            // 拍照
            if (self.chatShareMoreDelegate && [self.chatShareMoreDelegate respondsToSelector:@selector(didPickPhotoFromCamera)]) {
                [self.chatShareMoreDelegate didPickPhotoFromCamera];
            }
            break;
        }
        case 2:
        {
            // 文件
            if (self.chatShareMoreDelegate && [self.chatShareMoreDelegate respondsToSelector:@selector(didPickFileFromDocument)]) {
                [self.chatShareMoreDelegate didPickFileFromDocument];
            }
            break;
        }
        case 3:
        {
            // 电话
            if (self.chatShareMoreDelegate && [self.chatShareMoreDelegate respondsToSelector:@selector(didClickedAudio)]) {
                [self.chatShareMoreDelegate didClickedAudio];
            }
            break;
        }
        case 4:
        {
            // 视频
            if (self.chatShareMoreDelegate && [self.chatShareMoreDelegate respondsToSelector:@selector(didClickedVideo)]) {
                [self.chatShareMoreDelegate didClickedVideo];
            }
            break;
        }
        default:
            break;
    }
}


@end
