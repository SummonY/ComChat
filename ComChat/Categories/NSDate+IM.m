//
//  NSDate+IM.m
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NSDate+IM.h"

@implementation NSDate (IM)

#pragma mark 设置日期格式化时间
+ (NSDate *)formatLongDateTimeFromString:(NSString *)string
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return [dateFormatter dateFromString:string];
}

#pragma mark 格式化当前联系人日期
- (NSString *)formatRencentContactDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday fromDate:self];
    static NSDateFormatter *formatter = nil;
    
    NSString *dateString = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
    }
    

    if (todayComponents.day == dateComponents.day) {
        formatter.dateFormat = @"hh:mm";
        dateString = [formatter stringFromDate:self];
    }
    else if (todayComponents.day - 1 == dateComponents.day) {
        dateString = @"昨天";
    }
    else if (todayComponents.day - dateComponents.day <= 7) {
        if (WEEK_DAYS.count > dateComponents.weekday - 1) {
            dateString = WEEK_DAYS[dateComponents.weekday - 1];
        }
    } else {
        formatter.dateFormat = @"YYYY-MM-dd";
        dateString = [formatter stringFromDate:self];
    }
    return dateString;
}

#pragma mark 格式化消息日期
- (NSString *)formatChatMessageDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday fromDate:self];
    static NSDateFormatter *formatter = nil;
    
    NSString *dateString = nil;
    NSString *hourMinuteString = nil;
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
    }
    
    formatter.dateFormat = @"hh:mm";
    hourMinuteString = [formatter stringFromDate:self];
    
    if (todayComponents.day == dateComponents.day) {
        dateString = hourMinuteString;
    }
    else if (todayComponents.day - 1 == dateComponents.day) {
        dateString = [NSString stringWithFormat:@"昨天 %@", hourMinuteString];
    }
    else if (todayComponents.day - dateComponents.day <= 7) {
        if (WEEK_DAYS.count > dateComponents.weekday - 1) {
            dateString = [NSString stringWithFormat:@"%@ %@", WEEK_DAYS[dateComponents.weekday - 1], hourMinuteString];
        }
    }
    else {
        formatter.dateFormat = @"YYYY-MM-dd hh:mm";
        dateString = [formatter stringFromDate:self];
    }
    return dateString;
}


@end
