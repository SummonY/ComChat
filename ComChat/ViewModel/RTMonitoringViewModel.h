//
//  RTMonitoringViewModel.h
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RVMViewModel.h"

@interface RTMonitoringViewModel : RVMViewModel


- (void)searchMonitor:(NSString *)monitor;

- (void)sendMonitorInfo;


- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;


@end
