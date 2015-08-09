//
//  SettingViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/4.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "NewsViewModel.h"
#import <RACSubject.h>
#import <ReactiveCocoa.h>
#import "XMPP+IM.h"
#import "Macros.h"


@interface NewsViewModel()

@property (nonatomic, strong) RACSubject *updatedContentSignal;
@property (nonatomic, strong) NSManagedObjectContext *model;

@property (nonatomic, strong) NSMutableArray *fetchedNewsMessageArray;

@property (nonatomic, strong) NSFetchedResultsController *fetchedNewsResultsController;

@property (nonatomic, assign) NSNumber *totalUnreadNewsNum;

@end


@implementation NewsViewModel


#pragma mark 共享ViewModel
+ (instancetype)sharedViewModel
{
    static NewsViewModel *_sharedViewModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedViewModel = [[self alloc] init];
    });
    return _sharedViewModel;
}


#pragma mark 初始化
- (instancetype)init
{
    if (self = [super init]) {
        self.model = [[XMPPManager sharedManager] managedObjectContext_roster];
        
        [[XMPPManager sharedManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        self.fetchedNewsMessageArray = [[NSMutableArray alloc] init];
        
        self.updatedContentSignal = [[RACSubject subject] setNameWithFormat:@"%@updatedContentSignal", NSStringFromClass([NewsViewModel class])];
        @weakify(self)
        [self.didBecomeActiveSignal subscribeNext:^(id x) {
            @strongify(self)
            [self fetchLatestNews];
            //[self fetchNews];
        }];
        
        RAC(self, active) = [RACObserve([XMPPManager sharedManager], myJID) map:^id(id value) {
            if (value) {
                return @(YES);
            }
            return @(NO);
        }];
    }
    return self;
}


- (void)dealloc
{
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 请求最新新闻
- (void)fetchLatestNews
{
    NSLog(@"获取最新新闻...");
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:news"];
    
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addAttributeWithName:@"from" stringValue:[XMPPManager sharedManager].myJID.full];
    [iq addAttributeWithName:@"to" stringValue:XMPP_DOMAIN];
    [iq addChild:query];
    
    [[XMPPManager sharedManager].xmppStream sendElement:iq];
    
    NSLog(@"发送获取最新新闻IQ包：%@", iq);
    
}



#pragma mark 获取新闻
- (void)fetchNews
{
    NSLog(@"获取新闻...");
    NSError *error = nil;
    if (![self.fetchedNewsResultsController performFetch:&error]) {
        NSLog(@"获取新闻列表失败");
    }
    else {
        NSArray *dataArray = [self.fetchedNewsResultsController fetchedObjects];
        if (dataArray.count > 0) {
            NSLog(@"获取到的新闻列表: %@", dataArray);
        }
        [(RACSubject *)self.updatedContentSignal sendNext:nil];
    }
}





/////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////


#pragma mark 获得当前结果控制器
- (NSFetchedResultsController *)fetchedNewsResultsController
{
    NSLog(@"获取最新新闻...");
    if (!_fetchedNewsResultsController) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"" inManagedObjectContext:self.model];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"" ascending:NO];   // 按时间排序
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd, nil];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        _fetchedNewsResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.model sectionNameKeyPath:nil cacheName:nil];
        [_fetchedNewsResultsController setDelegate:self];
    }
    return _fetchedNewsResultsController;
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"消息控制器内容变化");
    [(RACSubject *)self.updatedContentSignal sendNext:nil];
    
}


//////////////////////////////////////////////////////////
#pragma mark DataSource
//////////////////////////////////////////////////////////


- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    //return [self.fetchedNewsResultsController fetchedObjects].count;
    return self.fetchedNewsMessageArray.count;
}


- (NewsMessageEntity *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.fetchedNewsMessageArray.count > 0) {
        NewsMessageEntity *newsMessageEntity = [NewsMessageEntity entityWithDictionary:[self.fetchedNewsMessageArray objectAtIndex:indexPath.row]];
        
        return  newsMessageEntity;
    }
    return nil;
    //return [self.fetchedNewsResultsController objectAtIndexPath:indexPath];
}





//////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
//////////////////////////////////////////////////////////////////////////////////////////////


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    if ([iq isNewsMessage]) {
        NSXMLElement *element = iq.childElement;
        
        for (NSXMLElement *item in element.children) {
            NSMutableDictionary *newsDict = [[NSMutableDictionary alloc] init];
            for (NSXMLElement *value in item.children) {
                [newsDict addEntriesFromDictionary:@{value.name : value.children[0]}];
            }
            [self.fetchedNewsMessageArray addObject:newsDict];
        }
        NSLog(@"接收到的新闻个数=%lu", (unsigned long)self.fetchedNewsMessageArray.count);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RELOAD_NEWS_MESSAGE" object:self userInfo:nil];
    }
    return YES;
}







@end







