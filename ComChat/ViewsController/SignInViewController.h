//
//  SignInViewController
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Reachability.h>

@interface SignInViewController : UIViewController


@property (nonatomic, strong) UITextField *userIDField;     // ID输入框
@property (nonatomic, strong) UITextField *userPWField;     // 密码输入框

@property (nonatomic, strong) Reachability *hostReach;      // 检测网络是否可达

- (IBAction)SignUpView:(id)sender;      // 新用户注册
- (IBAction)forgetPW:(id)sender;        // 用户忘记密码
- (IBAction)SignIn:(id)sender;          // 用户登录



@end
