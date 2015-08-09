//
//  EmotionManager.m
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//


#import "EmotionManager.h"

#define EMOTION_PLIST @"emotion.plist"

@interface EmotionManager()

@property (nonatomic, strong) NSArray* emotionsArray;

@end



@implementation EmotionManager

#pragma mark 设置单例
+ (instancetype)sharedManager
{
    static EmotionManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

#pragma mark 初始化表情数组
- (NSArray *)emotionsArray
{
    if (!_emotionsArray) {
        NSString *path = [[NSBundle mainBundle] pathForResource:EMOTION_PLIST ofType:nil];
        NSArray* array = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray* entities = [NSMutableArray arrayWithCapacity:array.count];
        EmotionEntity* entity = nil;
        NSDictionary* dic = nil;
        
        for (int i = 0; i < array.count; i++) {
            dic = array[i];
            entity = [EmotionEntity entityWithDictionary:dic atIndex:i];
            [entities addObject:entity];
        }
        _emotionsArray = entities;
    }
    return _emotionsArray;
}

#pragma mark 获取表情代码的名字
- (NSString*)imageNameForEmotionCode:(NSString*)code
{
    for (EmotionEntity *emotion in self.emotionsArray) {
        if ([emotion.code isEqualToString:code]) {
            return emotion.imageName;
        }
    }
    return nil;
}

#pragma mark 根据表情名称获取图片名称
- (NSString*)imageNameForEmotionName:(NSString*)name
{
    for (EmotionEntity *emotion in self.emotionsArray) {
        if ([emotion.name isEqualToString:name]) {
            return emotion.imageName;
        }
    }
    return nil;
}

#pragma mark 检查表情有效性
- (BOOL)checkValidEmotion:(NSString *)emotionName
{
    if ([self imageNameForEmotionName:emotionName]) {
        return YES;
    }
    return NO;
}


#pragma mark 删除[表情]
- (BOOL)deleteEmotionInTextView:(UITextView *)textView atRange:(NSRange)range
{
    NSString *deleteString =[textView.text substringWithRange:range];
    
    if ([deleteString isEqualToString:@"]"]) {
        
        NSRange leftRange = [textView.text rangeOfString:@"[" options:NSBackwardsSearch];
        if (leftRange.length > 0) {
            
            NSRange emotionRange = NSMakeRange(leftRange.location, range.location - leftRange.location + 1);
            NSString *emotionName = [textView.text substringWithRange:emotionRange];
            
            if ([[EmotionManager sharedManager] checkValidEmotion:emotionName]) {
                
                NSMutableString *textString = [NSMutableString stringWithString:textView.text];
                [textString deleteCharactersInRange:emotionRange];
                textView.text = textString;
                textView.selectedRange = NSMakeRange(emotionRange.location, 0);
                
                return YES;
            }
        }
    }
    return NO;
}

@end
