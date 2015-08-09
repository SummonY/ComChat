//
//  UserSignUpView.h
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Reachability.h>

@interface SignUpViewController : UIViewController

@property (nonatomic, strong) Reachability *hostReach;          // 检测网络是否可达

@property (nonatomic, strong) UITextField *userIDField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *passwordConfirm;

- (IBAction)SignUp:(id)sender;

@end
