//
//  AudioRecordPlayManager.m
//  ComChat
//
//  Created by D404 on 15/6/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "AudioRecordPlayManager.h"
#import "ResourceManager.h"
#import "XMPPManager.h"
#import <JSONKit.h>
#import "VoiceConverter.h"


@interface AudioRecordPlayManager()<AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *recordFileURL;
@property (nonatomic, copy)   NSString *recordUrlKey;
@property (nonatomic, strong) NSString *fileWavPath;

// 音频格式转换
@property (nonatomic, strong) NSString *originWav;
@property (nonatomic, strong) NSString *originAmr;
@property (nonatomic, strong) NSString *amrToWav;

@end


@implementation AudioRecordPlayManager

+ (instancetype)sharedManager
{
    static AudioRecordPlayManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc ] init];
        [_sharedManager activeAudioSession];
    });
    
    return _sharedManager;
}

#pragma mark 开启始终以扬声器模式播放声音
- (void)activeAudioSession
{
    self.session = [AVAudioSession sharedInstance];
    NSError *sessionError = nil;
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride
                             );
    if(!self.session) {
        NSLog(@"音频Session创建失败: %@", [sessionError description]);
    }
    else {
        [self.session setActive:YES error:nil];
    }
}

#pragma mark 根据数据播放音频
- (void)playWithData:(NSString *)data
{
    if (self.player) {
        if (self.player.isPlaying) {
            [self.player stop];
        }
        
        self.player.delegate = nil;
        self.player = nil;
    }
    
    //NSDictionary *audioDic = [data objectFromJSONString];
    //NSData *audioData = [audioDic objectForKey:@"data"];
    NSData *audioData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    
    NSError *playerError = nil;
    self.player = [[AVAudioPlayer alloc] initWithData:audioData error:&playerError];
    if (self.player)  {
        self.player.delegate = self;
        [self.player play];
    }
    else {
        NSLog(@"创建播放器失败: %@", [playerError description]);
    }
}


#pragma mark 获取用户名称
- (NSString *)getUserName:(NSString *)userJID
{
    NSString *userName = [NSString stringWithFormat:@"%@", [userJID componentsSeparatedByString:@"@"][0]];
    return userName;
}

#pragma mark 设置获取到的amr文件路径为wav文件路径
- (NSString *)setWavFilePathFromAmrFile:(NSString *)fileName
{
    NSString *wavFileName = [NSString stringWithFormat:@"%@", [fileName componentsSeparatedByString:@"."][0]];
    
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *wavfilePath = [cacheDir stringByAppendingPathComponent:wavFileName];
    
    return wavfilePath;
}



#pragma mark 音频会首先存储在服务器，服务器会返回存储路径把URL发送给接收方，接受方来下载
- (void)playWithUrl:(NSString *)url
{
    if (self.player) {
        if (self.player.isPlaying) {
            [self.player stop];
        }
        
        self.player.delegate = nil;
        self.player = nil;
    }
    
    NSURL *voiceUrl = [NSURL URLWithString:url];
    
    NSString *fileName = [voiceUrl lastPathComponent];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:fileName];
    
    // 从AMR转换为WAV格式
    NSLog(@"AMR格式转换为WAV格式...");
    NSString *wavFilePath = [self setWavFilePathFromAmrFile:fileName];
    [VoiceConverter amrToWav:filePath wavSavePath:wavFilePath];
    
    NSURL *URL = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:wavFilePath]) {
        URL = [NSURL fileURLWithPath:wavFilePath];
    }
    else {
        URL = [NSURL URLWithString:url];
    }
    
    
//    NSURL *URL = nil;
//    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//        URL = [NSURL fileURLWithPath:filePath];
//    }
//    else {
//        URL = [NSURL URLWithString:url];
//    }
    
    NSError *playerError = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&playerError];
    if (self.player)  {
        self.player.delegate = self;
        [self.player play];
    }
    else {
        NSLog(@"创建播放器失败: %@", [playerError description]);
    }
}

#pragma mark 开始录音
- (void)startRecord
{
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [ResourceManager generateAudioTimeKeyWithPrefix:[XMPPManager sharedManager].myJID.user];       // 原来做法
    //NSString *fileName = [ResourceManager generateWAVTimeKeyWithPrefix:[XMPPManager sharedManager].myJID.user];
    self.fileWavPath = [cacheDir stringByAppendingPathComponent:fileName];
    self.recordUrlKey = fileName;
    self.recordFileURL = [NSURL fileURLWithPath:self.fileWavPath];
    //self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileURL settings:nil error:nil];      // 原来做法
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileURL settings:[self getAudioRecorderSettingDict] error:nil];
    self.recorder.meteringEnabled = YES;
    
    [self.recorder prepareToRecord];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder record];
    
}

#pragma mark 停止记录语音
- (void)stopRecordSuccess:(void (^)(NSURL *url,NSTimeInterval time))success andFailed:(void (^)())failed
{
    NSTimeInterval time = self.recorder.currentTime;
    [self.recorder stop];
    
    if (time < 1.5) {
        if (failed) {
            failed();
        }
    }else{
        if (success) {
            /*
            NSLog(@"WAV格式转换为AMR格式...");
            
            NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *fileName = [ResourceManager generateAMRTimeKeyWithPrefix:[XMPPManager sharedManager].myJID.user];
            NSString *fileAmrPath = [cacheDir stringByAppendingPathComponent:fileName];
            [VoiceConverter wavToAmr:self.fileWavPath amrSavePath:fileAmrPath];
            self.recordFileURL = [NSURL fileURLWithPath:fileAmrPath];
            */
            success(self.recordFileURL,time);
        }
    }
}




#pragma mark 停止录音
- (void)stopRecordWithBlock:(void (^)(NSString *voiceName, NSData *voiceData, NSInteger time))block
{
    NSLog(@"录音完成，记录时间...");
    NSTimeInterval time = self.recorder.currentTime;
    [self.recorder stop];
    
    // 暂时通过AVAudioPlayer获取音频时长，后面用更合理的方法替换，定时器是一个不优美、不准确的解决方式
    NSTimeInterval duration = 0;
    
    NSError *playerError = nil;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileURL
                                                                        error:&playerError];
    if (audioPlayer)  {
        duration = audioPlayer.duration;
    }
    else {
        NSLog(@"创建播放器失败: %@", [playerError description]);
    }
    
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@", self.recordFileURL]];
    
    if (duration < 1.5) {
        NSLog(@"时间太短...time = %f, duration = %f", time, duration);
    }else{
        block(self.recordUrlKey, data, (NSInteger)(ceilf(duration)));
    }
}


/**
	获取录音设置
	@returns 录音设置
 */
- (NSDictionary*)getAudioRecorderSettingDict
{
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,//大端还是小端 是内存的组织方式
                                   //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                                   //                                   [NSNumber numberWithInt: AVAudioQualityMedium],AVEncoderAudioQualityKey,//音频编码质量
                                   nil];
    return recordSetting;
}


@end
