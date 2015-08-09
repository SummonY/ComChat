//
//  AudioView.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AudioViewDelegate;


@interface AudioView : UIView

@property (nonatomic, weak) id<AudioViewDelegate> delegate;

@end

@protocol AudioViewDelegate <NSObject>

- (void)didFinishRecordingAudioWithUrlKey:(NSString *)voiceName data:(NSData *)voiceData time:(NSInteger)time;
- (void)didFinishRecordingAudioWithData:(NSData *)data bodyName:(NSString *)time;

@end