//
//  MonitorsCell.m
//  ComChat
//
//  Created by D404 on 15/6/17.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "MonitorsCell.h"

@interface MonitorsCell()

@property (nonatomic, strong) UILabel *monitorName;
@property (nonatomic, strong) UILabel *monitorStatus;
@property (nonatomic, strong) UIImageView *bottomLine;

@end


@implementation MonitorsCell


#pragma mark 初始化Cell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 监测点名称
        self.monitorName = [[UILabel alloc] initWithFrame:CGRectMake(50, 2, 200, 20)];
        self.monitorName.font = [UIFont boldSystemFontOfSize:14.f];
        self.monitorName.textColor = [UIColor blackColor];
        self.monitorName.highlightedTextColor = self.monitorName.textColor;
        [self.contentView addSubview:self.monitorName];
        
        // 监测点状态
        self.monitorStatus = [[UILabel alloc] initWithFrame:CGRectMake(50, 30, 200, 15)];
        self.monitorStatus.font = [UIFont systemFontOfSize:12.f];
        self.monitorStatus.textColor = [UIColor grayColor];
        self.monitorStatus.highlightedTextColor = self.detailTextLabel.textColor;
        [self.contentView addSubview:self.monitorStatus];
        
        // 底部线条
        self.bottomLine = [[UIImageView alloc] initWithFrame:CGRectMake(50, 48, [UIScreen mainScreen].bounds.size.width - 50, 1)];
        self.bottomLine.image = [UIImage imageNamed:@"splitLine"];
        [self.contentView addSubview:self.bottomLine];
        
        // 背景颜色
        self.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return self;
}


#pragma mark 设置监测点
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    
    return YES;
}




@end
