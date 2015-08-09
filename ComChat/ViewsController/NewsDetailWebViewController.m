//
//  NewsDetailWebView.m
//  ComChat
//
//  Created by D404 on 15/7/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewsDetailWebViewController.h"
#import "UIViewAdditions.h"

@interface NewsDetailWebViewController ()

@property (nonatomic, retain) UIWebView *webView;

@end


@implementation NewsDetailWebViewController

- (instancetype)init
{
    if (self = [super init]) {
    }
    
    return self;
}

#pragma mark 初始化
- (id)initWithURL:(NSString *)url
{
    if (self = [self init]) {
        self.urlString = url;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setHidesBottomBarWhenPushed:NO];
    [super viewWillDisappear:animated];
}


- (void)loadView
{
    [super loadView];
    
    self.view = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width , [[UIScreen mainScreen] bounds].size.height)];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // 设置导航条
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"新闻详细";
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
    NSURL *url=[NSURL URLWithString:self.urlString];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    self.webView.scrollView.delegate=self;
    self.webView.backgroundColor=[UIColor grayColor];
    [self.view addSubview:self.webView];
}




@end
