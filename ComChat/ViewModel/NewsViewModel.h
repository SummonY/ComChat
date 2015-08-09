//
//  SettingViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"
#import "XMPPManager.h"
#import "NewsMessageEntity.h"

@interface NewsViewModel : RVMViewModel

@property (nonatomic, readonly) RACSignal *updatedContentSignal;
@property (nonatomic, readonly) NSNumber *totalUnreadNewsNum;

+ (instancetype)sharedViewModel;

- (void)fetchLatestNews;
- (void)fetchNews;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (NewsMessageEntity *)objectAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath;


@end
