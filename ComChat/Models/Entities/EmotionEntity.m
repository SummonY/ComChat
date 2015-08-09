//
//  EmotionEntity.m
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "EmotionEntity.h"

@implementation EmotionEntity

#pragma mark 字典实例化实体
+ (EmotionEntity *)entityWithDictionary:(NSDictionary*)dic atIndex:(int)index
{
    EmotionEntity* entity = [[EmotionEntity alloc] init];
    entity.name = dic[@"name"];
    entity.code = [NSString stringWithFormat:@"[%d]", index];
    entity.imageName = [NSString stringWithFormat:@"Expression_%d", index + 1];
    
    return entity;
}


@end
