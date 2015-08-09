//
//  NewsMessageEntity.h
//  ComChat
//
//  Created by D404 on 15/7/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewsMessageEntity : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *messageDigest;
@property (nonatomic, copy) NSString *url;

+ (id)entityWithDictionary:(NSDictionary *)dict;



@end
