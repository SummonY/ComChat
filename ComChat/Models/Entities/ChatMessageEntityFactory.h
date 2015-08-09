//
//  ChatMessageBaseEntity.h
//  ComChat
//
//  Created by D404 on 15/6/7.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <XMPPMessageArchiving_Message_CoreDataObject.h>
#import <XMPPRoomMessageCoreDataStorageObject.h>


typedef NS_ENUM(NSUInteger, ChatMessageType) {
    ChatMessageType_Text,
    ChatMessageType_Image,
    ChatMessageType_Voice,
    ChatMessageType_Audio,
    ChatMessageType_Video,
    ChatMessageType_News,
    ChatMessageType_Monitor,
    ChatMessageType_Unknown
};

#pragma mark 定义基类
@interface ChatMessageBaseEntity : NSObject

@property (nonatomic, assign) ChatMessageType type;
@property (nonatomic, assign) BOOL isOutgoing;

@end

#pragma mark 定义文本类
@interface ChatMessageTextEntity : ChatMessageBaseEntity

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSArray *emotionRanges;
@property (nonatomic, strong) NSArray *emotionImageNames;

- (instancetype)initWithText:(NSString *)text;
- (void)parseAllKeywords;

+ (NSString *)JSONStringFromText:(NSString *)text;


@end

#pragma mark 定义图片类
@interface ChatMessageImageEntity : ChatMessageBaseEntity

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, copy) NSString *url;

+ (NSString *)JSONStringWithImageWidth:(CGFloat)width height:(CGFloat)height url:(NSString *)url;

@end


#pragma mark 定义语音类
@interface ChatMessageVoiceEntity : ChatMessageBaseEntity

@property (nonatomic, strong) NSString *data;
@property (nonatomic, assign) NSInteger time;
@property (nonatomic, copy) NSString *url;

+ (id)entityWithDictionary:(NSDictionary *)dict;
+ (NSString *)JSONStringWithAudioTime:(NSInteger)time url:(NSString *)url;
+ (NSString *)JSONStringWithAudioData:(NSString *)data time:(NSString *)time;
- (void)playAudioWithProgressBlock:(void (^)(CGFloat progress))progressBlock;

@end



#pragma mark 定义电话类
@interface ChatMessageAudioEntity : ChatMessageBaseEntity

@property (nonatomic, assign) NSInteger time;



@end












#pragma mark 定义视频类
@interface ChatMessageVideoEntity : ChatMessageBaseEntity

@property (nonatomic, assign) NSInteger time;



@end






#pragma mark 定义监测点类
@interface ChatmessageMonitorEntity : ChatMessageBaseEntity

@property (nonatomic, copy) NSString *monitorPoint;
@property (nonatomic, copy) NSDate *date;




@end



@interface ChatMessageEntityFactory : NSObject

+ (ChatMessageBaseEntity *)messageFromJSONString:(NSString *)JSONString;
+ (NSString *)recentContactLastMessageFromJSONString:(NSString *)JSONString;

@end
