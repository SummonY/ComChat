//
//  RTCVideoChatViewController.h
//  ComChat
//
//  Created by D404 on 15/6/25.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RTCVideoChatViewController : UIViewController

@property (nonatomic, strong) NSString *userJid;


@property (nonatomic, strong) UIButton *hangUpBtn;


- (instancetype)initWithUserJid:(NSString *)userJID;


@end
