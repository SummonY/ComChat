//
//  EmotionView.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "EmotionView.h"
#import <NimbusPagingScrollView.h>
#import "EmotionManager.h"
#import "UIViewAdditions.h"


#define LEFT_MARGIN     16
#define TOP_MARGIN      20
#define ROW_COUNT       3
#define COLUMN_COUNT    7
#define ROW_SPACE       13        //(320 - LEFT_MARGIN * 2 - FACE_WIDTH * COLUMN_COUNT) / 6
#define COLUMN_SPACE    20
#define FACE_WIDTH      30
#define PAGE_CONTROL_HEIGHT 20



///////////////////////////////////////////////////////
#pragma mark - EmotionPageView
///////////////////////////////////////////////////////

@interface EmotionPageView : UIView <NIPagingScrollViewPage>

@end

@implementation EmotionPageView
@synthesize pageIndex = _pageIndex;

- (void)setPageIndex:(NSInteger)pageIndex {
    _pageIndex = pageIndex;
}

@end


@interface EmotionView()<NIPagingScrollViewDataSource, NIPagingScrollViewDelegate>

@property (nonatomic, strong) NSArray* emotionArray;
@property (nonatomic, strong) NIPagingScrollView* scrollView;
@property (nonatomic, strong) UIPageControl* pageControl;


@end


@implementation EmotionView

#pragma mark 初始化框架
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.emotionArray = [[EmotionManager sharedManager] emotionsArray];
        self.backgroundColor = RGBCOLOR(244, 244, 244);
        
        _scrollView = [[NIPagingScrollView alloc] initWithFrame:self.bounds];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delegate = self;
        _scrollView.dataSource = self;
        [self addSubview:_scrollView];
        
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
        [_pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
        _pageControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
        [self addSubview:_pageControl];
        
        [self.scrollView reloadData];
    }
    return self;
}

#pragma mark 子视图
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.pageControl.frame = CGRectMake(0.f, self.bounds.size.height - PAGE_CONTROL_HEIGHT * 3,
                                        self.bounds.size.width, PAGE_CONTROL_HEIGHT);
}


#pragma mark 发送表情
- (void)sendAction
{
    if (self.emotionDelegate && [self.emotionDelegate respondsToSelector:@selector(didEmotionViewSendAction)]) {
        [self.emotionDelegate didEmotionViewSendAction];
    }
}

#pragma mark 检查是否为最后一个图标位置，若是，则放置删除按钮
- (BOOL)checkIsLastPostionInPageWithRowIndex:(NSInteger)rowIndex columnIndex:(NSInteger)columnIndex
{
    if (ROW_COUNT - 1 == rowIndex && COLUMN_COUNT - 1 == columnIndex) {
        return YES;
    }
    return NO;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NIScrollViewDataSource
//////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark 计算页面个数
- (NSInteger)numberOfPagesInPagingScrollView:(NIPagingScrollView *)pagingScrollView
{
    int numInPage = ROW_COUNT * COLUMN_COUNT;
    int pageNum = ceil((float)_emotionArray.count / numInPage);
    [_pageControl setNumberOfPages:pageNum];
    return pageNum;
}

#pragma mark 页面滚动
- (UIView<NIPagingScrollViewPage> *)pagingScrollView:(NIPagingScrollView *)pagingScrollView pageViewForIndex:(NSInteger)pageIndex
{
    int row = ROW_COUNT;
    int column = COLUMN_COUNT;
    
    EmotionPageView *pageView = (EmotionPageView *)[pagingScrollView dequeueReusablePageWithIdentifier:@"EmotionPageView"];
    if (pageView == nil) {
        pageView = [[EmotionPageView alloc] initWithFrame:CGRectMake(0, 0, column * (FACE_WIDTH + ROW_SPACE),
                                                                       row * (FACE_WIDTH + COLUMN_SPACE))];
        pageView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer* gest = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(faceTaped:)];
        [pageView addGestureRecognizer:gest];
    }
    
    NSInteger previousPageTotalCount = 0;
    NSInteger postionIndex = 0;
    NSInteger previousDeleteBtnCount = 0;
    NSInteger emtionIndex = 0;
    for (int i = 0; i < row; i++) {
        for (int j = 0; j < column; j++) {
            // 最后一个添加删除按钮
            if ([self checkIsLastPostionInPageWithRowIndex:i columnIndex:j]) {
                break;
            }
            previousPageTotalCount = row * column * pageIndex;
            previousDeleteBtnCount = pageIndex;
            postionIndex = i * column + j;
            
            emtionIndex = previousPageTotalCount + postionIndex - previousDeleteBtnCount;
            
            UIImageView* imgView = (UIImageView*)[pageView viewWithTag:1000 + postionIndex];
            if (emtionIndex < _emotionArray.count) {
                EmotionEntity* entity = [_emotionArray objectAtIndex:emtionIndex];
                
                if (imgView == nil) {
                    imgView = [[UIImageView alloc] initWithFrame:
                               CGRectMake(j * (FACE_WIDTH + ROW_SPACE) + LEFT_MARGIN,
                                          i * (FACE_WIDTH + COLUMN_SPACE) + TOP_MARGIN,
                                          FACE_WIDTH, FACE_WIDTH)];
                    imgView.tag = 1000 + postionIndex;
                    imgView.backgroundColor = [UIColor clearColor];
                    imgView.userInteractionEnabled = YES;
                    [pageView addSubview:imgView];
                }
                imgView.image = [UIImage imageNamed:entity.imageName];
            }
            else {
                [imgView removeFromSuperview];
            }
        }
    }
    
    // 添加删除按钮
    UIButton *deleteBtn = (UIButton*)[pageView viewWithTag:2000 + pageIndex];
    if (!deleteBtn) {
        deleteBtn = [[UIButton alloc] initWithFrame:
                     CGRectMake((column - 1) * (FACE_WIDTH + ROW_SPACE) + LEFT_MARGIN,
                                (row - 1) * (FACE_WIDTH + COLUMN_SPACE) + TOP_MARGIN,
                                FACE_WIDTH, FACE_WIDTH)];
        [deleteBtn setImage:[UIImage imageNamed:@"DeleteEmoticonBtn"] forState:UIControlStateNormal];
        [deleteBtn setImage:[UIImage imageNamed:@"DeleteEmoticonBtnHL"] forState:UIControlStateHighlighted];
        [deleteBtn addTarget:self action:@selector(deleteAction)
            forControlEvents:UIControlEventTouchUpInside];
        deleteBtn.tag = 2000 + pageIndex;
        [pageView addSubview:deleteBtn];
    }
    return pageView;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NIPagingScrollViewDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)pagingScrollViewDidChangePages:(NIPagingScrollView *)pagingScrollView
{
    self.pageControl.currentPage = pagingScrollView.centerPageIndex;
}

#pragma mark 页面变化
- (void)pageChanged:(id)sender
{
    [self.scrollView setCenterPageIndex:self.pageControl.currentPage];
}

#pragma mark 删除表情
- (void)deleteAction
{
    if (self.emotionDelegate && [self.emotionDelegate respondsToSelector:@selector(didEmotionViewDeleteAction)]) {
        [self.emotionDelegate didEmotionViewDeleteAction];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)faceTaped:(UIGestureRecognizer*)gest
{
    CGPoint point = [gest locationInView:_scrollView.centerPageView];
    
    int row = ROW_COUNT;
    int column = COLUMN_COUNT;
    
    // 选择表情区域需要往右上角移动半个space
    CGPoint offset = CGPointMake(ROW_SPACE / 2.f, COLUMN_SPACE / 2.f);
    CGRect effectRect = CGRectMake(LEFT_MARGIN - offset.x, TOP_MARGIN - offset.y,
                                   column * (FACE_WIDTH + ROW_SPACE), row * (FACE_WIDTH + COLUMN_SPACE));
    
    if (CGRectContainsPoint(effectRect, point)) {
        NSInteger currentRow = floor((point.y + offset.y - TOP_MARGIN) / (FACE_WIDTH + COLUMN_SPACE));
        NSInteger currentcolumn = floor((point.x + offset.x - LEFT_MARGIN) / (FACE_WIDTH + ROW_SPACE));
        
        if (![self checkIsLastPostionInPageWithRowIndex:currentRow columnIndex:currentcolumn]) {
            
            NSInteger previousPageTotalCount = row * column * _scrollView.centerPageIndex;
            NSInteger index = previousPageTotalCount + column * currentRow + currentcolumn;
            NSInteger previousDeleteBtnCount = _scrollView.centerPageIndex;
            NSInteger realIndex = index - previousDeleteBtnCount;
            
            if (realIndex < _emotionArray.count) {
                if ([self.emotionDelegate respondsToSelector:@selector(emotionSelectedWithName:)]) {
                    EmotionEntity *emtionEntity = [_emotionArray objectAtIndex:realIndex];
                    [self.emotionDelegate emotionSelectedWithName:[emtionEntity name]];
                }
            }
        }
    }
}


@end
