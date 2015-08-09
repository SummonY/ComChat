//
//  NewsListCell.m
//  ComChat
//
//  Created by D404 on 15/6/11.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewsListCell.h"
#import "UIViewAdditions.h"
#import "NewsMessageEntity.h"



@interface NewsListCell()

@property (nonatomic, strong) UILabel *newsTitle;
@property (nonatomic, strong) UILabel *newsTime;
@property (nonatomic, strong) UILabel *newsContent;
@property (nonatomic, strong) NSURL *newsUrl;
@property (nonatomic, strong) NSMutableArray *newsPhotos;

@property (nonatomic, strong) UIImageView *bottomLine;

@end



@implementation NewsListCell


#pragma mark 初始化风格
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    
        // 新闻标题
        self.newsTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 3, 230, 30)];
        self.newsTitle.font = [UIFont systemFontOfSize:15.f];
        self.newsTitle.textColor = [UIColor blackColor];
        self.newsTitle.highlightedTextColor = self.newsTitle.textColor;
        [self.contentView addSubview:self.newsTitle];
        
        // 新闻日期
        self.newsTime = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 70, 20)];
        self.newsTime.font = [UIFont systemFontOfSize:12.f];
        self.newsTime.textColor = [UIColor grayColor];
        self.newsTime.highlightedTextColor = self.newsTime.textColor;
        self.newsTime.right = self.right - 5;
        [self.contentView addSubview:self.newsTime];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, [UIScreen mainScreen].bounds.size.width, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
    
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
}

#pragma mark 加载子视图
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, self.height);
}

#pragma mark 更新Cell
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    if ([object isKindOfClass:[NewsMessageEntity class]]) {
        NewsMessageEntity *entity = (NewsMessageEntity *)object;
        
        self.newsTitle.text = [NSString stringWithFormat:@"%@", entity.title];
        self.newsTime.text = [NSString stringWithFormat:@"%@", entity.date];
        self.newsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", entity.url]];
    }
    return YES;
}



@end
