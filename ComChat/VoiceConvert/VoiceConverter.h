//
//  VoiceConverter.h
//  ComChat
//
//  Created by D404 on 15/7/23.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VoiceConverter : NSObject

+ (int)amrToWav:(NSString*)_amrPath wavSavePath:(NSString*)_savePath;

+ (int)wavToAmr:(NSString*)_wavPath amrSavePath:(NSString*)_savePath;

@end
