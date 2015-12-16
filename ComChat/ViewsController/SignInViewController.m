//
//  SignInViewController.m
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "SignInViewController.h"
#import "SignUpViewController.h"
#import "UIView+Toast.h"
#import "Macros.h"
#import <MBProgressHUD.h>
#import "XMPPManager.h"
#import "MainTabBarController.h"

@interface SignInViewController () {
    NSString *userID;
    NSString *userPW;
    
    MBProgressHUD* HUD;
}

@property (nonatomic, assign) BOOL isSignIn;

@end

@implementation SignInViewController


@synthesize userIDField = _userIDField;         // 用户ID输入框
@synthesize userPWField = _userPWField;         // 用户密码输入框
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
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];   // 获取屏幕大小
    
    self.view = [[UIView alloc] initWithFrame:screenBounds];
    
    /* 设置背景图片 */
    UIImageView *bgImage = [[UIImageView alloc] initWithFrame:screenBounds];
    [bgImage setImage:[UIImage imageNamed:@"login_bg.jpg"]];
    
    /* 设置LOGO */
    UIImageView* logoImage = [[UIImageView alloc] initWithFrame:CGRectMake((screenBounds.size.width - 90) / 2, 40, 90, 90)];
    [logoImage setImage:[UIImage imageNamed:@"user_head_default"]];
    
    
    /* 设置用户名输入框 */
    _userIDField = [[UITextField alloc] initWithFrame:CGRectMake(2, 150, screenBounds.size.width - 4, 40)];
    [_userIDField setPlaceholder:@"请输入ID"];
    _userIDField.backgroundColor = [UIColor whiteColor];
    [_userIDField setFont:[UIFont systemFontOfSize:14]];
    _userIDField.clearButtonMode = UITextFieldViewModeAlways;
    _userIDField.delegate = self;
    
    
    /* 设置密码输入框 */
    _userPWField = [[UITextField alloc] initWithFrame:CGRectMake(2, 191, screenBounds.size.width - 4, 40)];
    [_userPWField setPlaceholder:@"请输入密码"];
    _userPWField.backgroundColor = [UIColor whiteColor];
    [_userPWField setFont:[UIFont systemFontOfSize:14]];
    [_userPWField setSecureTextEntry:YES];
    _userPWField.clearButtonMode = UITextFieldViewModeAlways;
    _userPWField.delegate = self;
    
    
    /* 设置登录按钮 */
    UIButton *signInBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [signInBtn setFrame:CGRectMake(10, 250, screenBounds.size.width - 20, 38)];
    [signInBtn setBackgroundImage:[UIImage imageNamed:@"login_btn_blue_nor"] forState:UIControlStateNormal];
    [signInBtn setImage:[UIImage imageNamed:@"login_btn_blue_press"] forState:UIControlStateSelected];
    [signInBtn setTitle:@"登录" forState:UIControlStateNormal];
    signInBtn.titleLabel.textColor = [UIColor whiteColor];
    [signInBtn.layer setCornerRadius:3.0];
    [signInBtn addTarget:self action:@selector(SignIn:) forControlEvents:UIControlEventTouchUpInside];
    
    
    /* 设置忘记密码按钮 */
    UIButton *forgetPWBtn = [[UIButton alloc] initWithFrame:CGRectMake(3, screenBounds.size.height - 45, 100, 40)];
    [forgetPWBtn setTitle:@"忘记密码?" forState:UIControlStateNormal];
    [forgetPWBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    forgetPWBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [forgetPWBtn addTarget:self action:@selector(forgetPW:) forControlEvents:UIControlEventTouchUpInside];
    
    
    /* 设置用户注册按钮 */
    UIButton *signUpBtn = [[UIButton alloc] initWithFrame:CGRectMake(screenBounds.size.width - 73, screenBounds.size.height - 45, 70, 40)];
    [signUpBtn setTitle:@"新用户" forState:UIControlStateNormal];
    signUpBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [signUpBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [signUpBtn addTarget:self action:@selector(SignUpView:) forControlEvents:UIControlEventTouchUpInside];
    
    
    /* 添加到主视图 */
    [self.view addSubview:bgImage];
    [self.view addSubview:logoImage];
    [self.view addSubview:_userIDField];
    [self.view addSubview:_userPWField];
    [self.view addSubview:signUpBtn];
    [self.view addSubview:forgetPWBtn];
    [self.view addSubview:signInBtn];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];    
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

#pragma mark 检查信息是否完整
-(BOOL)checkInformationReady
{
    userID = _userIDField.text;
    userPW = _userPWField.text;
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
    
    return YES;
}

#pragma mark 检测网络是否连接正常
- (BOOL)checkNetwork
{
    _hostReach = [Reachability reachabilityWithHostname:XMPP_HOST_NAME];
    NetworkStatus status = [_hostReach currentReachabilityStatus];
    
    if (status == NotReachable) {
        [self.view makeToast:@"网络不可用，请检查您的网络设置" duration:1.0 position:CSToastPositionTop];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark 用户登录
- (IBAction)SignIn:(id)sender
{
    if (![self checkInformationReady]) {        // 检查输入
        return ;
    }
    if (![self checkNetwork]) {                 // 检查网络状态
        return ;
    }
    
    NSLog(@"用户登录...");
    self.isSignIn = YES;
    
    // 隐藏键盘
    [_userIDField resignFirstResponder];
    [_userPWField resignFirstResponder];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.delegate = self;
    HUD.labelText = @"正在登录...";
    [HUD show:YES];
    [self setField:_userIDField forKey:XMPP_USER_ID];
    [self setField:_userPWField forKey:XMPP_PASSWORD];
    [[XMPPManager sharedManager] connectThenSignIn];
}


#pragma mark 进入新用户注册界面
- (IBAction)SignUpView:(id)sender
{
    NSLog(@"打开用户注册界面");
    
    SignUpViewController* signUpViewController = [[SignUpViewController alloc] init];
    [self.navigationController pushViewController:signUpViewController animated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}


#pragma mark 忘记密码
-(IBAction)forgetPW:(id)sender
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"找回密码", nil];
    sheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [sheet showInView:self.view];
}

#pragma mark 触发找回密码事件
-(void)actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"用户点击找回密码按钮！");
    
}


// 点击空白，键盘自动消失
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_userIDField resignFirstResponder];
    [_userPWField resignFirstResponder];
}

//屏幕上移
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
}

//屏幕下移
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
}

- (void)animateTextField:(UITextField *)textField up:(BOOL)up
{
    const int movementDistance = 20;
    const float movementDuration = 0.3f;
    int movement = (up ? -movementDistance:movementDistance);
    [UIView beginAnimations:@"anim" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


/////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream delegate
/////////////////////////////////////////////////////////////////////

/**
 * This method is called after authentication has successfully finished.
 * If authentication fails for some reason, the xmppStream:didNotAuthenticate: method will be called instead.
 **/
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"用户认证通过");
    
    [HUD setHidden:YES];
    
    if (self.isSignIn) {
        NSLog(@"登录成功，进入主界面...");
        MainTabBarController *mainTabBarController = [[MainTabBarController alloc] init];
        [self presentViewController:mainTabBarController animated:YES completion:^{}];
    }
    self.isSignIn = NO;
}

/**
 * This method is called if authentication fails.
 **/
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    [HUD setHidden:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"登录失败"
                                                        message:@"账号或密码有误，请重新输入"
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
    [alertView show];
}



@end
