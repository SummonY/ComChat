//
//  ChatMoreView.h
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Nimbus/NimbusLauncher.h>

@protocol ChatShareMoreViewDelegate;

@interface ChatShareMoreView : NILauncherView

@property (nonatomic, weak) id<ChatShareMoreViewDelegate> chatShareMoreDelegate;

@end



@protocol ChatShareMoreViewDelegate <NSObject>

@optional

- (void)didPickPhotoFromLibrary;
- (void)didPickPhotoFromCamera;
- (void)didPickFileFromDocument;
- (void)didClickedAudio;
- (void)didClickedVideo;

@end