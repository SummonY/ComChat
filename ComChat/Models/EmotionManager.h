//
//  EmotionManager.h
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EmotionEntity.h"


@interface EmotionManager : NSObject

+ (instancetype)sharedManager;

- (NSArray *)emotionsArray;
- (NSString *)imageNameForEmotionCode:(NSString*)code;
- (NSString *)imageNameForEmotionName:(NSString*)name;
- (BOOL)checkValidEmotion:(NSString *)emotionName;
- (BOOL)deleteEmotionInTextView:(UITextView *)textView atRange:(NSRange)range;


@end
