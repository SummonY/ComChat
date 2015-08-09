//
//  ResourceManager.m
//  ComChat
//
//  Created by D404 on 15/6/9.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ResourceManager.h"
#import <AFHTTPRequestOperation.h>

@implementation ResourceManager

+ (instancetype)sharedManager
{
    static ResourceManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc ] init];
    });
    
    return _sharedManager;
}

#pragma mark 图片压缩
- (UIImage *) imageWithImageSimple:(UIImage*) image scaledToSize:(CGSize) newSize
{
    newSize.height=image.size.height*(newSize.width/image.size.width);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark 上传图片
- (void)uploadImage:(UIImage *)image
          keyPrefix:(NSString *)keyPrefix
      completeBlock:(void (^)(BOOL success, CGFloat width, CGFloat height))completeBlock
{
    NSLog(@"上传图片...，keyPrefix = %@", keyPrefix);
    // scale image with mode UIViewContentModeScaleAspectFit
    UIImage* newImage = image;
    CGFloat kMaxLength = 400.f;
    if (image.size.width > kMaxLength || image.size.height > kMaxLength) {
        //CGRect rect = [image convertRect:CGRectMake(0.f, 0.f, kMaxLength, kMaxLength)                         withContentMode:UIViewContentModeScaleAspectFit];
        //newImage = [image transformWidth:rect.size.width height:rect.size.height rotate:YES];
        newImage = [self imageWithImageSimple:image scaledToSize:CGSizeMake(300, 300)];
    }
    
    
    
    
}

#pragma mark - Upload & Download File (Audio & Video)
- (void)uploadFileWithUrlkey:(NSString *)urlkey
               progressBlock:(void (^)(NSString *key, float progress))progressBlock
               completeBlock:(void (^)(BOOL success,  NSString *key))completeBlock
{
    NSLog(@"上传文件...");
    /*
    NSString *token = [QNAuthPolicy defaultToken];
    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil progressHandler:progressBlock//获取上传进度
                                                        params:nil checkCrc:YES cancellationSignal:nil];
    
    QNUploadManager *upManager = [QNUploadManager sharedInstanceWithRecorder:nil recorderKeyGenerator:nil];
    NSData *data = [[IMCache sharedCache] cachedDataForUrlKey:urlkey];
    [upManager putData:data key:urlkey
                 token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                     if (info.statusCode == QN_STATUS_CODE_SUCCESS) {
                         completeBlock(YES, key);
                     }
                     else {
                         completeBlock(NO, nil);
                     }
                 } option:opt];
     */
}

#pragma mark 根据URL下载文件
- (void)downloadFileWithUrl:(NSString*)url
              progressBlock:(void (^)(CGFloat progress))progressBlock
              completeBlock:(void (^)(BOOL success, NSError *error))completeBlock
{
    NSLog(@"根据URL下载文件...");
    
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    
    NSString *fileName = [url lastPathComponent];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:fileName];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:NO]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        progressBlock((float)totalBytesRead / totalBytesExpectedToRead);
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        completeBlock(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completeBlock(NO, error);
    }];
    
    [operation start];
}


#pragma mark -  Generate Key

+ (NSString *)generateImageTimeKeyWithPrefix:(NSString *)keyPrefix
{
    NSString *timeString = [ResourceManager generateTimeKey];
    return [NSString stringWithFormat:@"%@++___++%@++___++%@.png", keyPrefix, timeString, timeString];
}

+ (NSString *)generateAudioTimeKeyWithPrefix:(NSString *)keyPrefix
{
    NSString *timeString = [ResourceManager generateTimeKey];
    return [NSString stringWithFormat:@"%@-%@.caf", keyPrefix, timeString];
}

// 生成wav文件后缀
+ (NSString *)generateWAVTimeKeyWithPrefix:(NSString *)keyPrefix
{
    NSString *timeString = [ResourceManager generateTimeKey];
    return [NSString stringWithFormat:@"%@++___++%@++___++%@.wav", keyPrefix, timeString, timeString];          // 将wav格式转换为amr格式
}

// 生成AMR文件后缀
+ (NSString *)generateAMRTimeKeyWithPrefix:(NSString *)keyPrefix
{
    NSString *timeString = [ResourceManager generateTimeKey];
    return [NSString stringWithFormat:@"%@++___++%@++___++%@.amr", keyPrefix, timeString, timeString];          // 将wav格式转换为amr格式
}

+ (NSString *)generateTimeKey
{
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    [f setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSString *timeString = [f stringFromDate:[NSDate date]];
    return timeString;
}


@end
