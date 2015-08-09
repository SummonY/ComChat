//
//  ResourceManager.h
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ResourceManager : NSObject

+ (instancetype)sharedManager;

- (void)uploadImage:(UIImage *)image
          keyPrefix:(NSString *)keyPrefix
      completeBlock:(void (^)(BOOL success, CGFloat width, CGFloat height))completeBlock;

//upload file with urlkey
- (void)uploadFileWithUrlkey:(NSString *)urlkey
               progressBlock:(void (^)(NSString *key, float progress))progressBlock
               completeBlock:(void (^)(BOOL success,  NSString *key))completeBlock;

// download file with url
- (void)downloadFileWithUrl:(NSString*)url
              progressBlock:(void (^)(CGFloat progress))progressBlock
              completeBlock:(void (^)(BOOL success, NSError *error))completeBlock;

// yyyy-MM-dd-HH-mm-ss.jpg
+ (NSString *)generateImageTimeKeyWithPrefix:(NSString *)keyPrefix;

// yyyy-MM-dd-HH-mm-ss.caf
+ (NSString *)generateAudioTimeKeyWithPrefix:(NSString *)keyPrefix;

// yyyy-MM-dd-HH-mm-ss.wav
+ (NSString *)generateWAVTimeKeyWithPrefix:(NSString *)keyPrefix;

// yyyy-MM-dd-HH-mm-ss.amr
+ (NSString *)generateAMRTimeKeyWithPrefix:(NSString *)keyPrefix;

+ (NSString *)generateTimeKey;

@end
