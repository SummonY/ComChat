//
//  AudioRecordPlayManager.h
//  ComChat
//
//  Created by D404 on 15/6/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface AudioRecordPlayManager : NSObject


+ (instancetype)sharedManager;

- (void)playWithData:(NSString *)data;
- (void)playWithUrl:(NSString *)url;

- (void)startRecord;
- (void)stopRecordWithBlock:(void (^)(NSString *voiceName, NSData *voiceData, NSInteger time))block;
- (void)stopRecordSuccess:(void (^)(NSURL *url,NSTimeInterval time))success andFailed:(void (^)())failed;

/**
 获取录音设置
 @returns 录音设置
 */
- (NSDictionary*)getAudioRecorderSettingDict;

@end
