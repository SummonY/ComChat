//
//  NSDate+IM.h
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//
#import <Foundation/Foundation.h>

#define WEEK_DAYS @[@"星期日", @"星期一", @"星期二", @"星期三", @"星期四", @"星期五", @"星期六"]

@interface NSDate (IM)


+ (NSDate *)formatLongDateTimeFromString:(NSString *)string;        // yyyy-MM-dd HH:mm:ss

- (NSString *)formatRencentContactDate;
- (NSString *)formatChatMessageDate;


@end
