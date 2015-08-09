//
//  UserSignUpView.m
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "SignUpViewController.h"
#import "UIView+Toast.h"
#import <MBProgressHUD.h>
#import "XMPPManager.h"
#import "Macros.h"

@interface SignUpViewController () {
    /* 用户名、密码和确认密码*/
    NSString *userID;
    NSString *userPW;
    NSString *userPWcfm;
    
    UIScrollView *mainScroll;
    
    MBProgressHUD* HUD;     // 进度条
}

@end


@implementation SignUpViewController

@synthesize userIDField = _userIDField;
@synthesize passwordField = _passwordField;
@synthesize passwordConfirm = _passwordConfirm;

@synthesize hostReach = _hostReach;             // 主机是否可达


#pragma mark 初始化
- (id)init
{
    self = [super init];
    if (self) {
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];

    // 获取屏幕大小
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    //self.view = [[UIView alloc] initWithFrame:screenBounds];
    self.view = [[UIView alloc] initWithFrame:screenBounds];
    //设置界面背景颜色
    self.view.backgroundColor = [UIColor cyanColor];
    
    // 设置滚动条
    mainScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 10)];
    [mainScroll setBackgroundColor:[UIColor lightTextColor]];
    [mainScroll setContentSize:CGSizeMake(screenBounds.size.width, screenBounds.size.height + 10)];
    mainScroll.delegate = self;
    
    
    // 设置用户名和密码区域
    _userIDField = [[UITextField alloc] initWithFrame:CGRectMake(10, 30, screenBounds.size.width - 20, 40)];
    [_userIDField setPlaceholder:@"请输入ID"];
    _userIDField.backgroundColor = [UIColor whiteColor];
    [_userIDField setFont:[UIFont systemFontOfSize:14]];
    _userIDField.clearButtonMode = UITextFieldViewModeAlways;
    _userIDField.delegate = self;
    
    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(10, 80, screenBounds.size.width - 20, 40)];
    [_passwordField setPlaceholder:@"请输入密码"];
    _passwordField.backgroundColor = [UIColor whiteColor];
    [_passwordField setFont:[UIFont systemFontOfSize:14]];
    [_passwordField setSecureTextEntry:YES];
    _passwordField.clearButtonMode = UITextFieldViewModeAlways;
    _passwordField.delegate = self;
    
    _passwordConfirm = [[UITextField alloc] initWithFrame:CGRectMake(10, 130, screenBounds.size.width - 20, 40)];
    [_passwordConfirm setPlaceholder:@"请输入确认密码"];
    _passwordConfirm.backgroundColor = [UIColor whiteColor];
    [_passwordConfirm setFont:[UIFont systemFontOfSize:14]];
    [_passwordConfirm setSecureTextEntry:YES];
    _passwordConfirm.clearButtonMode = UITextFieldViewModeAlways;
    _passwordConfirm.delegate = self;
    
    // 设置登录按钮
    UIButton *signUpBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 190, screenBounds.size.width - 40, 38)];
    [signUpBtn setBackgroundImage:[UIImage imageNamed:@"login_btn_blue_nor"] forState:UIControlStateNormal];
    [signUpBtn setImage:[UIImage imageNamed:@"login_btn_blue_press"] forState:UIControlStateSelected];
    [signUpBtn setTitle:@"注册" forState:UIControlStateNormal];
    [signUpBtn addTarget:self action:@selector(SignUp:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置注册协议标签
    UILabel *ptlLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 235, screenBounds.size.width - 40, 20)];
    [ptlLabel setText:@"点击”注册“，表示遵守<<软件许可及服务协议>>！"];
    [ptlLabel setFont:[UIFont systemFontOfSize:11]];
    
    // 添加到主视图
    [mainScroll addSubview:_userIDField];
    [mainScroll addSubview:_passwordField];
    [mainScroll addSubview:_passwordConfirm];
    [mainScroll addSubview:signUpBtn];
    [mainScroll addSubview:ptlLabel];
    
    [self.view addSubview:mainScroll];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor lightTextColor]];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"新用户注册";
    
    /* 为滚动条添加手势 */
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchScrollView)];
    [recognizer setNumberOfTapsRequired:1];
    [recognizer setNumberOfTouchesRequired:1];
    [self->mainScroll addGestureRecognizer:recognizer];
}

#pragma mark 返回到登录界面
- (IBAction)returnToSignIn:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        
    }
    [self.navigationController setNavigationBarHidden:YES];
    [super viewWillDisappear:animated];
}


#pragma mark 检查信息是否完整
-(BOOL)checkInformationReady{
    userID = _userIDField.text;
    userPW = _passwordField.text;
    userPWcfm = _passwordConfirm.text;
    
    if ([userID isEqualToString:@""])
    {
        [self.view makeToast:@"请输入ID" duration:1.0 position:CSToastPositionCenter];
        return NO;
    }
    else if ([userPW isEqualToString:@""])
    {
        [self.view makeToast:@"请输入密码" duration:1.0 position:CSToastPositionCenter];
        return NO;
    }
    else if ([userPWcfm isEqualToString:@""])
    {
        [self.view makeToast:@"请输入确认密码" duration:1.0 position:CSToastPositionCenter];
        return NO;
    }
    if (![userPW isEqual:userPWcfm]) {
        [self.view makeToast:@"两次输入密码不相同，请重新输入！" duration:1.5 position:CSToastPositionCenter];
        return NO;
    }
    
    return YES;
}

#pragma mark 检测网络是否连接正常
- (BOOL)checkNetwork
{
    _hostReach = [Reachability reachabilityWithHostname:XMPP_HOST_NAME];
    NetworkStatus status = [_hostReach currentReachabilityStatus];
    
    if (status == NotReachable) {
        [self.view makeToast:@"网络不可用，请检查您的网络设置" duration:1.0 position:CSToastPositionCenter];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark 用户注册
- (IBAction)SignUp:(id)sender
{
    // 点击注册键盘消失
    [_userIDField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [_passwordConfirm resignFirstResponder];
    
    if (![self checkInformationReady]) {
        return ;
    }
    if (![self checkNetwork]) {
        return ;
    }
    
    NSLog(@"正在进行用户注册...");
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.delegate = self;
    HUD.labelText = @"正在注册...";
    [HUD show:YES];
    
    [self setField:_userIDField forKey:XMPP_USER_ID];
    [self setField:_passwordField forKey:XMPP_PASSWORD];
    [[XMPPManager sharedManager] connectThenSignUp];
     
}

#pragma mark 设置输入框文本
- (void)setField:(UITextField *)field forKey:(NSString *)key
{
    if (field.text != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:field.text forKey:key];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


#pragma mark 点击ScrollView，键盘自动消失
- (void)touchScrollView
{
    [_userIDField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [_passwordConfirm resignFirstResponder];
}



/////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream delegate
/////////////////////////////////////////////////////////////////////////////

/**
 * This method is called after registration of a new user has successfully finished.
 * If registration fails for some reason, the xmppStream:didNotRegister: method will be called instead.
 **/
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    [HUD setHidden:YES];
    [self.view makeToast:@"用户注册成功" duration:1.0 position:CSToastPositionCenter];
}

/**
 * This method is called if registration fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error
{
    NSLog(@"注册失败error:%@", error);
    [HUD setHidden:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"注册失败"
                                                        message:@"用户已存在，请重新选择用户名进行注册；若已注册，请直接进行登录。"
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
    [alertView show];
}


@end
