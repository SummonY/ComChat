//
//  EmotionEntity.h
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmotionEntity : NSObject

+ (EmotionEntity *)entityWithDictionary:(NSDictionary*)dic atIndex:(int)index;

@property (nonatomic, copy) NSString* code;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* imageName;


@end
