//
//  ChatMessageBaseEntity.m
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ChatMessageEntityFactory.h"
#import "ResourceManager.h"
#import "AudioRecordPlayManager.h"
#import <ReactiveCocoa.h>
#import <ASIHTTPRequest.h>
#import "ParserKeyword.h"
#import "EmotionManager.h"
#import "KeywordRegularParser.h"



///////////////////////////////////////////////////////////////////////////////
#pragma mark 定义发送消息基类
///////////////////////////////////////////////////////////////////////////////

@implementation ChatMessageBaseEntity

- (instancetype)init
{
    if (self = [super init]) {
        self.type = ChatMessageType_Unknown;
        self.isOutgoing = NO;
    }
    return self;
}

@end




///////////////////////////////////////////////////////////////////////////////
#pragma mark 定义发送消息文本类
///////////////////////////////////////////////////////////////////////////////

@implementation ChatMessageTextEntity

- (instancetype)initWithText:(NSString *)text
{
    if (self = [super init]) {
        self.text = text;
    }
    return self;
}

+ (NSString *)JSONStringFromText:(NSString *)text
{
    NSDictionary *jsonDic = @{@"type" : @"text",
                              @"data" : text};
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"生成JSON对象数据错误, %@", error);
        return nil;
    }
    
}

- (void)parseAllKeywords
{
    if (ChatMessageType_Text == self.type && self.text.length > 0) {
        if (!self.emotionRanges) {
            NSString *trimedString = self.text;
            
            self.emotionRanges = [KeywordRegularParser keywordRangesOfEmotionInString:self.text
                                                                           trimedString:&trimedString];
            self.text = trimedString;
            NSMutableArray* emotionImageNames = [NSMutableArray arrayWithCapacity:self.emotionRanges.count];
            
            for (ParserKeyword *keyworkEntity in self.emotionRanges) {
                NSString* keyword = keyworkEntity.keyword;
                
                for (EmotionEntity *emotionEntity in [EmotionManager sharedManager].emotionsArray) {
                    if ([keyword isEqualToString:emotionEntity.name]) {
                        [emotionImageNames addObject:emotionEntity.imageName];
                        break;
                    }
                }
            }
            self.emotionImageNames = emotionImageNames;
        }
        if (!self.text.length) {
            self.text = @" ";
                for (ParserKeyword *keyword in self.emotionRanges) {
                    keyword.range = NSMakeRange(keyword.range.location + 1, keyword.range.length);
                }
        }
    }
}

@end



///////////////////////////////////////////////////////////////////////////////
#pragma mark 图片类
///////////////////////////////////////////////////////////////////////////////



@implementation ChatMessageImageEntity

#pragma mark 数组实例化
+ (id)entityWithArray:(NSArray *)array
{
    if ([array isKindOfClass:[NSArray class]] && array.count > 0) {
        NSDictionary *dic = array[0];
        return [[self class] entityWithDictionary:dic];
    }
    return nil;
}

#pragma mark 字典实例化
+ (id)entityWithDictionary:(NSDictionary *)dic
{
    if (dic) {
        ChatMessageImageEntity *entity = [[ChatMessageImageEntity alloc] init];
        entity.width = [dic[@"width"] floatValue];
        entity.height = [dic[@"height"] floatValue];
        entity.url = dic[@"data"];
        return entity;
    }
    return nil;
}

/*
#pragma mark 产生JSON字符串
+ (NSString *)JSONStringWithImageWidth:(CGFloat)width height:(CGFloat)height url:(NSString *)url
{
    NSDictionary *jsonDic = @{@"type"   : @"image",
                              @"data"   : @[@{
                                                @"width"    :[NSNumber numberWithFloat:width],
                                                @"height"   :[NSNumber numberWithFloat:height],
                                                @"url"      : url
                                                }]
                              
                              };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"JSON 对象化错误， %@", error);
        return nil;
    }
}
*/

#pragma mark 产生JSON字符串
+ (NSString *)JSONStringWithImageWidth:(CGFloat)width height:(CGFloat)height url:(NSString *)url
{
    NSDictionary *jsonDic = @{@"type"   : @"image",
                              @"width"    :[NSNumber numberWithFloat:width],
                              @"height"   :[NSNumber numberWithFloat:height],
                              @"data"   : url
                              };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"JSON 对象化错误， %@", error);
        return nil;
    }
}



@end




///////////////////////////////////////////////////////////////////////////////
#pragma mark 语音类
///////////////////////////////////////////////////////////////////////////////


#pragma mark ChatMessageVoiceEntity

typedef void (^ProgressBlock)(CGFloat progress);
typedef void (^CompleteBlock)();

@interface ChatMessageVoiceEntity()

@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) CompleteBlock completeBlock;

@end


@implementation ChatMessageVoiceEntity


#pragma mark 采用字典实例化
+ (id)entityWithDictionary:(NSDictionary *)dict
{
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        ChatMessageVoiceEntity *entity = [[ChatMessageVoiceEntity alloc] init];
        entity.data = dict[@"data"];
        entity.time = [dict[@"time"] integerValue];
        entity.url = dict[@"data"];
        return entity;
    }
    return nil;
}

/*
#pragma mark JSON序列化
+ (NSString *)JSONStringWithAudioTime:(NSInteger)time url:(NSString *)url
{
    NSDictionary *jsonDic = @{@"type"   : @"voice",
                              @"data"   : @{
                                      @"time"   :[NSNumber numberWithInteger:time],
                                      @"url"    : url
                                      }
                              };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"JSON对象化错误, %@", error);
        return nil;
    }
}
 */

#pragma mark JSON序列化
+ (NSString *)JSONStringWithAudioTime:(NSInteger)time url:(NSString *)url
{
    NSDictionary *jsonDic = @{@"type"   : @"voice",
                              @"time"   :[NSNumber numberWithInteger:time],
                              @"data"   : url
                              };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"JSON对象化错误, %@", error);
        return nil;
    }
}


#pragma mark JSON序列化
+ (NSString *)JSONStringWithAudioData:(NSString *)data time:(NSString *)time
{
    NSDictionary *jsonDic = @{@"type"   : @"voice",
                              @"data"   : @{
                                      @"data"    : data,
                                      @"time"    : time
                                      }
                              };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:kNilOptions error:&error];
    if (!error) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"JSON对象化错误, %@", error);
        return nil;
    }
}

/*
#pragma mark 播放音频BASE64方式
- (void)playAudioWithProgressBlock:(void (^)(CGFloat progress))progressBlock
{
    NSLog(@"播放音频...");
    
    if (self.isOutgoing) {
        [[AudioRecordPlayManager sharedManager] playWithData:self.url];
        progressBlock(1.0f);
    }
    else {
        [[AudioRecordPlayManager sharedManager] playWithData:self.data];
        progressBlock(1.0f);
    }
}
*/

#pragma mark 播放音频
- (void)playAudioWithProgressBlock:(void (^)(CGFloat))progressBlock
{
    NSLog(@"播放音频...");
    
    if (self.isOutgoing) {
        [[AudioRecordPlayManager sharedManager] playWithUrl:self.url];
        progressBlock(1.0f);
    }
    else {
        [[AudioRecordPlayManager sharedManager] playWithUrl:self.url];
        progressBlock(1.0f);
    }
}



@end



///////////////////////////////////////////////////////////////////////////////
#pragma mark 电话类
///////////////////////////////////////////////////////////////////////////////

@implementation ChatMessageAudioEntity





@end





///////////////////////////////////////////////////////////////////////////////
#pragma mark 视频类
///////////////////////////////////////////////////////////////////////////////


@implementation ChatMessageVideoEntity





@end





///////////////////////////////////////////////////////////////////////////////
#pragma mark 监测点类
///////////////////////////////////////////////////////////////////////////////

@implementation ChatmessageMonitorEntity




@end



///////////////////////////////////////////////////////////////////////////////
#pragma mark ChatMessageEntityFactory
///////////////////////////////////////////////////////////////////////////////

@implementation ChatMessageEntityFactory

#pragma mark JSON字符串对象
+ (id)objectFromJSONString:(NSString *)JSONString
{
    if (JSONString) {
        NSError *error = nil;
        NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *JSONObject = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:&error];
        if (error) {
            NSLog(@"消息体JSON错误， %@", error);
            JSONObject = @{@"type"  : @"text",
                           @"data"  : @"Not a JSON String."
                           };
        }
        return JSONObject;
    }
    return nil;
}

#pragma mark 字典实例化
+ (id)entityWithDictionary:(NSDictionary *)dic
{
    if (dic) {
        NSString *typeStr = dic[@"type"];
        ChatMessageBaseEntity *messageEntity = nil;
        ChatMessageType type = [ChatMessageEntityFactory typeFromString:typeStr];
        
        switch (type) {
            case ChatMessageType_Text:
            {
                messageEntity = [[ChatMessageTextEntity alloc] initWithText:dic[@"data"]];
                break;
            }
            case ChatMessageType_Image:
            {
                //messageEntity = [ChatMessageImageEntity entityWithArray:dic[@"data"]];              // TODO：JSON格式修改
                messageEntity = [ChatMessageImageEntity entityWithDictionary:dic];
                break;
            }
            case ChatMessageType_Voice:
            {
                //messageEntity = [ChatMessageVoiceEntity entityWithDictionary:dic[@"data"]];         // TODO：JSON格式修改
                messageEntity = [ChatMessageVoiceEntity entityWithDictionary:dic];
                break;
            }
//            case ChatMessageType_Audio:
//            {
//                messageEntity = [ChatMessageAudioEntity initWithText:dic[@"data"]];
//                break;
//            }
//            case ChatMessageType_Video:
//            {
//                messageEntity = [ChatMessageVideoEntity initWithText:dic[@"data"]];
//                break;
//            }
            case ChatMessageType_Monitor:
            {
                break;
            }
            default:
                break;
        }
        messageEntity.type = type;
        return messageEntity;
    }
    return nil;
}


#pragma mark 从JSON字符串获取消息
+ (ChatMessageBaseEntity *)messageFromJSONString:(NSString *)JSONString
{
    id JSONObject = [ChatMessageEntityFactory objectFromJSONString:JSONString];
    if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        id message = [ChatMessageEntityFactory entityWithDictionary:JSONObject];
        return message;
    }
    return nil;
}

#pragma mark 从string类型获取类型信息
+ (ChatMessageType)typeFromString:(NSString *)typeStr
{
    ChatMessageType type = ChatMessageType_Unknown;
    if (typeStr.length > 0) {
        if ([typeStr isEqualToString:@"text"]) {
            type = ChatMessageType_Text;
        } else if ([typeStr isEqualToString:@"image"]) {
            type = ChatMessageType_Image;
        } else if ([typeStr isEqualToString:@"voice"]) {
            type = ChatMessageType_Voice;
        } else if ([typeStr isEqualToString:@"news"]) {
            type = ChatMessageType_News;
        }
    }
    return type;
}


#pragma mark 当前联系人最新消息从JSON字符串
+ (NSString *)recentContactLastMessageFromJSONString:(NSString *)JSONString
{
    id object = [ChatMessageEntityFactory messageFromJSONString:JSONString];
    NSString *lastMessage = @"";
    
    if ([object isKindOfClass:[ChatMessageTextEntity class]]) {
        lastMessage = ((ChatMessageTextEntity *)object).text;
    } else if ([object isKindOfClass:[ChatMessageImageEntity class]]) {
        lastMessage = @"[图片]";
    } else if ([object isKindOfClass:[ChatMessageVoiceEntity class]]) {
        lastMessage = @"[语音]";
    } else if ([object isKindOfClass:[ChatMessageAudioEntity class]]) {
        lastMessage = @"[电话]";
    } else if ([object isKindOfClass:[ChatMessageVideoEntity class]]) {
        lastMessage = @"[视频]";
    }
    return lastMessage;
}


@end
