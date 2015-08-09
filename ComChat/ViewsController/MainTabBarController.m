//
//  MainTabBarController.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "MainTabBarController.h"
#import "MessageViewController.h"
#import "ContactsViewController.h"
#import "NewsViewController.h"
#import "RTMonitoringViewController.h"
#import <ReactiveCocoa.h>


@interface MainTabBarController () {
    
}

@end


@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewControllers = [self generateViewControllers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 创建tabBar ViewControllers
- (NSArray *)generateViewControllers
{
    Class NavClass = [UINavigationController class];
    
    MessageViewController *messageViewController = [[MessageViewController alloc] initWithStyle:UITableViewStylePlain];
    ContactsViewController *contactsViewController = [[ContactsViewController alloc] init];
    NewsViewController *newsViewController = [[NewsViewController alloc] init];
    RTMonitoringViewController *rtMonitoringViewController = [[RTMonitoringViewController alloc] init];
    
    
    UINavigationController *messageNavController = [[NavClass alloc] initWithRootViewController:messageViewController];
    UINavigationController *contactsNavController = [[NavClass alloc] initWithRootViewController:contactsViewController];
    UINavigationController *newsNavController = [[NavClass alloc] initWithRootViewController:newsViewController];
    UINavigationController *rtMonitorNavController = [[NavClass alloc] initWithRootViewController:rtMonitoringViewController];
    
    messageNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"消息"
                                                                    image:[[UIImage imageNamed:@"tab_recent_nor"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                            selectedImage:[[UIImage imageNamed:@"tab_recent_press"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    contactsNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"通讯录"
                                                                     image:[[UIImage imageNamed:@"tab_buddy_nor"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                             selectedImage:[[UIImage imageNamed:@"tab_buddy_press"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    newsNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"新闻"
                                                                     image:[[UIImage imageNamed:@"tab_qworld_nor"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                             selectedImage:[[UIImage imageNamed:@"tab_qworld_press"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    rtMonitorNavController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"监测"
                                                                    image:[[UIImage imageNamed:@"tab_location_nor"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                            selectedImage:[[UIImage imageNamed:@"tab_location_press"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    UIView *customBgView = [[UIView alloc] initWithFrame:self.tabBar.bounds];
    customBgView.backgroundColor = [UIColor whiteColor];
    [self.tabBar insertSubview:customBgView atIndex:0];
    self.tabBar.opaque = YES;
    
    
    RAC(messageNavController.tabBarItem, badgeValue) = [RACObserve(messageViewController.messageViewModel, totalUnreadMessagesNum)
                                                   map:^id(NSNumber *value) {
                                                       if ([value intValue] > 0) {
                                                           return [value stringValue];
                                                       }
                                                       else {
                                                           return nil;
                                                       }
                                                   }];
    
    RAC(contactsNavController.tabBarItem, badgeValue) = [RACObserve(contactsViewController.contactsViewModel, unsubscribedCountNum)
                                                map:^id(NSNumber *value) {
                                                    if ([value intValue] > 0) {
                                                        return [value stringValue];
                                                    }
                                                    else {
                                                        return nil;
                                                    }
                                                }];
    RAC(newsNavController.tabBarItem, badgeValue) = [RACObserve(newsViewController.newsViewModel, totalUnreadNewsNum)
                                                         map:^id(NSNumber *value) {
                                                             if ([value intValue] > 0) {
                                                                 return [value stringValue];
                                                             }
                                                             else {
                                                                 return nil;
                                                             }
                                                         }];
    
    return @[messageNavController, contactsNavController, newsNavController, rtMonitorNavController];
}


@end
