//
//  NewsMessageEntity.m
//  ComChat
//
//  Created by D404 on 15/7/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewsMessageEntity.h"

@implementation NewsMessageEntity


#pragma mark 字典实例化
+ (id)entityWithDictionary:(NSDictionary *)dict
{
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        NewsMessageEntity *entity = [[NewsMessageEntity alloc] init];
        entity.title = dict[@"title"];
        entity.date = dict[@"time"];
        entity.url = dict[@"url"];
        return entity;
    }
    return nil;
}





@end
