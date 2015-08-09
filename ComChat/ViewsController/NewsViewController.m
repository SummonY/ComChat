//
//  SettingViewController.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewsViewController.h"
#import "XMPPManager.h"
#import "NewsListCell.h"
#import "NewsDetailWebViewController.h"
#import "Macros.h"


@interface NewsViewController ()<UIAlertViewDelegate>


@end

@implementation NewsViewController


#pragma mark 初始化
- (id)init
{
    if (self = [super init]) {
        self.newsViewModel = [NewsViewModel sharedViewModel];
        
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDataNofity)
                                                     name:@"RELOAD_NEWS_MESSAGE"
                                                   object:nil];
    }
    return self;
}

#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    [searchBar setPlaceholder:@"搜索"];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.navigationController.navigationBar setBackgroundColor:[UIColor lightTextColor]];
    self.navigationItem.title = @"新闻";

    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchNewsAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tabBarController.tabBar setHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark 获取最新新闻
- (void)fetchNewsAction
{
    NSLog(@"刷新获取最新新闻...");
    [self.newsViewModel fetchLatestNews];
    [self.refreshControl endRefreshing];
}


- (void)reloadDataNofity
{
    [self.tableView reloadData];
}



////////////////////////////////////////////////////////////////////////
#pragma mark Search Bar
////////////////////////////////////////////////////////////////////////


#pragma mark 点击搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索...");
    searchBar.showsCancelButton = YES;
}

#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"点击取消按钮");
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

















////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.newsViewModel numberOfItemsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NewsListCell";
    
    id object = [self.newsViewModel objectAtIndexPath:indexPath];
    NewsListCell *newsListCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!newsListCell) {
        newsListCell = [[NewsListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [(NewsListCell *)newsListCell shouldUpdateCellWithObject:object];
    
    return newsListCell;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"点击新闻行");
    
    id object = [self.newsViewModel objectAtIndexPath:indexPath];
    
    NewsMessageEntity *entity = (NewsMessageEntity *)object;
    NSString *urlString = [[NSString stringWithFormat:@"%@", entity.url] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"url = %@", urlString);
    
    NewsDetailWebViewController *newsDetailWebViewController = [[NewsDetailWebViewController alloc] initWithURL:urlString];
    [self.navigationController pushViewController:newsDetailWebViewController animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}





////////////////////////////////////////////////////////////
#pragma mark UISearchBarDelegate
////////////////////////////////////////////////////////////

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}



@end
