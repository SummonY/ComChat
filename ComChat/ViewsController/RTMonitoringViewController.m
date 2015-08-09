//
//  NewsViewController.m
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "RTMonitoringViewController.h"
#import "XMPPManager.h"
#import "MonitorsCell.h"
#import "Macros.h"

@interface RTMonitoringViewController ()

@end








@implementation RTMonitoringViewController



#pragma mark 初始化
- (id)init
{
    if (self = [super init]) {
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
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
    self.navigationItem.title = @"监测";
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /* 初始化刷新控制 */
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchMonitorsAction) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark 刷新获取监测点
- (void)fetchMonitorsAction
{
    NSLog(@"刷新获取监测点...");
    [self sendMonitorInfo];
    [self.refreshControl endRefreshing];
}


#pragma mark 请求指定监测点信息
- (void)sendMonitorInfo
{
    NSLog(@"发送监测点请求...");
    
    XMPPJID *serverJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@", XMPP_DOMAIN]];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:serverJID];
    
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"jabber:iq:jianting"];
    
    NSXMLElement *sid = [NSXMLElement elementWithName:@"sid"];
    [sid setStringValue:@"52"];
    
    [query addChild:sid];
    [iq addChild:query];
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
}



////////////////////////////////////////////////////////////////////////
#pragma mark Search Bar
////////////////////////////////////////////////////////////////////////


#pragma mark 点击搜索
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"正在输入搜索内容...");
    searchBar.showsCancelButton = YES;
}



#pragma mark 点击搜索按钮
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"开始搜索...");
    
    NSString *searchTerm = [searchBar text];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.rtMonitoringViewModel searchMonitor:searchTerm];
    [self.tableView reloadData];
}




#pragma mark 点击取消按钮
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"点击取消按钮");
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}










///////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
///////////////////////////////////////////////////////////////////////////


#pragma mark Section数目
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *monitorsCellIdentifier = @"MonitorsCell";
    
    id object = [self.rtMonitoringViewModel objectAtIndexPath:indexPath];
    MonitorsCell *monitorsCell = [tableView dequeueReusableCellWithIdentifier:monitorsCellIdentifier];
    
    if (!monitorsCell) {
        monitorsCell = [[MonitorsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:monitorsCellIdentifier];
    }
    
    [(MonitorsCell *)monitorsCell shouldUpdateCellWithObject:object];
    return monitorsCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}



@end
