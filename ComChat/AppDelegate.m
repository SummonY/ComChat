//
//  AppDelegate.m
//  ComChat
//
//  Created by D404 on 15/6/3.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "AppDelegate.h"
#import "Macros/Macros.h"
#import "RTCManager.h"
#import "SignInViewController.h"

@interface AppDelegate () {
    Reachability *hostReach;
}

@property (nonatomic, strong) SignInViewController *signInViewController;

@end

@implementation AppDelegate

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (status == NotReachable) {
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"网络不可达" message:@"未检测到网络" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alterView show];
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    /* 初始化导航条 */
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.signInViewController = [[SignInViewController alloc] init];
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.signInViewController];
    [navigation.navigationBar setBackgroundColor:[UIColor blueColor]];
    [navigation setNavigationBarHidden:YES];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
    
    // 开启RTC引擎
    //[[RTCManager sharedManager] startEngine];
    
    /* 开启网络状态监听 */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    hostReach = [Reachability reachabilityWithHostname:XMPP_HOST_NAME];
    [hostReach startNotifier];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
