//
//  GroupChatViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "GroupChatViewModel.h"
#import <RACSubject.h>
#import "ChatMessageEntityFactory.h"
#import "ResourceManager.h"
#import "Macros.h"
#import <ASIHTTPRequest/ASIFormDataRequest.h>
#import "NSDate+IM.h"


@interface GroupChatViewModel()

@property (nonatomic, strong) RACSignal *fetchRoomLaterSignal;
@property (nonatomic, strong) RACSignal *fetchRoomEarlierSignal;

@property (nonatomic, strong) NSFetchedResultsController *fetchedEarlierResultsController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedLaterResultsController;

@property (nonatomic, strong) NSManagedObjectContext *model;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;

@property (nonatomic, strong) NSDate *earlierDate;
@property (nonatomic, strong) NSDate *laterDate;
@property (nonatomic, assign) NSInteger newMessageCount;

@end



@implementation GroupChatViewModel


#pragma mark 初始化model
- (instancetype)initWithModel:(id)model
{
    if (self = [super init]) {
        self.model = model;
        
        self.fetchRoomLaterSignal = [[RACSubject subject] setNameWithFormat:@"%@fetchRoomLaterSignal", NSStringFromClass([GroupChatViewModel class])];
        
        self.fetchRoomEarlierSignal = [[RACSubject subject] setNameWithFormat:@"%@fetchRoomEarlierSignal", NSStringFromClass([GroupChatViewModel class])];
        self.totalResultsSectionArray = [NSMutableArray array];
        self.earlierResultsSectionArray = [NSMutableArray array];
        self.newMessageCount = 0;
    }
    return self;
}



#pragma mark 给群组发送文本消息
- (void)sendMessageWithText:(NSString *)text
{
    if (text.length > 0) {
        NSString *JSONString = [ChatMessageTextEntity JSONStringFromText:text];
        [[XMPPManager sharedManager] sendChatMessage:JSONString
                                               toGroupJID:self.groupJID];
    }
}


#pragma mark 图片压缩
- (UIImage *)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    newSize.height=image.size.height*(newSize.width/image.size.width);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark 发送图片消息
- (void)sendMessageWithImage:(UIImage *)image
{
    NSLog(@"发送图片...");
    UIImage *newImage = image;
    if (image.size.width > 500.f || image.size.height > 500.f) {
        newImage = [self imageWithImageSimple:image scaledToSize:CGSizeMake(500, 500)];
    }
    NSString *imageName = [ResourceManager generateImageTimeKeyWithPrefix:self.groupJID.full];
    NSString *url = [[NSString alloc] initWithFormat:@"http://%@:%@/image/%@", XMPP_DOMAIN, HTTP_FILE_SERVER_PORT, imageName];
    NSString *JSONString = [ChatMessageImageEntity JSONStringWithImageWidth:newImage.size.width height:newImage.size.height url:url];
    NSData *imageData;
    if (UIImagePNGRepresentation(newImage)) {
        imageData = UIImagePNGRepresentation(newImage);
    } else {
        imageData = UIImageJPEGRepresentation(newImage, 0.5);
    }
    
    NSString *imageUrl = [[NSString alloc] initWithFormat:@"http://%@:%@/image/", XMPP_DOMAIN, HTTP_FILE_SERVER_PORT];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:imageUrl]];
    [request setPostValue:@"imagePost" forKey:@"image"];
    [request setUsername:@"admin"];
    [request setPassword:@"admin"];
    [request setData:imageData withFileName:imageName andContentType:@"image/png" forKey:@"image"];
    [request setShowAccurateProgress:YES];
    [request setCompletionBlock:^{
        NSString *message = [request responseString];
        //NSLog(@"服务器回复响应信息%@", message);
        [[XMPPManager sharedManager] sendChatMessage:JSONString toGroupJID:self.groupJID];
    }];
    [request setFailedBlock: ^{
        NSError *error = request.error;
        NSLog(@"发送图片失败, %@", error);
    }];
    [request setTimeOutSeconds:10000];
    [request startAsynchronous];
    
}


#pragma mark 发送音频消息:采用HTTP协议将语音以URL的方式存储在服务器，服务器转发URL给接受方。
- (void)sendMessageWithAudioTime:(NSInteger)time data:(NSData *)voiceData urlkey:(NSString *)voiceName
{
    NSLog(@"发送音频消息...");
    
    NSString *url = [[NSString alloc] initWithFormat:@"http://%@:%@/voice/%@", XMPP_DOMAIN, HTTP_FILE_SERVER_PORT, voiceName];
    NSLog(@"语音名称:%@", voiceName);
    NSString *JSONString = [ChatMessageVoiceEntity JSONStringWithAudioTime:time url:url];
    
    NSString *voiceUrl = [[NSString alloc] initWithFormat:@"http://%@:%@/voice/", XMPP_DOMAIN, HTTP_FILE_SERVER_PORT];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:voiceUrl]];
    [request setPostValue:@"imagePost" forKey:@"image"];
    [request setUsername:@"admin"];
    [request setPassword:@"admin"];
    [request setData:voiceData withFileName:voiceName andContentType:@"voice/caf" forKey:@"voice"];
    [request setShowAccurateProgress:YES];
    [request setCompletionBlock:^{
        NSString *message = [request responseString];
        //NSLog(@"服务器回复响应信息%@", message);
        [[XMPPManager sharedManager] sendChatMessage:JSONString toGroupJID:self.groupJID];
    }];
    [request setFailedBlock: ^{
        NSError *error = request.error;
        NSLog(@"发送图片失败, %@", error);
    }];
    [request setTimeOutSeconds:10000];
    [request startAsynchronous];
}


#pragma mark 更新获取到的日期
- (void)updateFetchLaterDate
{
    NSLog(@"更新群组内消息获取到的日期...");
    
    if (self.fetchedLaterResultsController.sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedLaterResultsController.sections lastObject];
        if (sectionInfo) {
            XMPPRoomMessageCoreDataStorageObject *laterMessage = [[sectionInfo objects] firstObject];
            
            if (laterMessage) {
                self.laterDate = laterMessage.localTimestamp;
            }
        }
    }
}

#pragma mark 合并获取到的结果
- (void)mergeAllFetchedResults
{
    NSLog(@"合并群组内消息获取到的结果...");
    
    @synchronized(self) {
        [self.totalResultsSectionArray removeAllObjects];
        
        /* 合并最新聊天数组和历史聊天数组 */
        if (self.fetchedLaterResultsController.sections.count) {
            [self.totalResultsSectionArray addObjectsFromArray:self.fetchedLaterResultsController.sections];
        }
        if (self.earlierResultsSectionArray.count) {
            [self.totalResultsSectionArray addObjectsFromArray:self.earlierResultsSectionArray];
        }
    }
}

#pragma mark 返回全部消息数组
- (NSMutableArray *)totalResultsSectionArray
{
    @synchronized(self) {
        return _totalResultsSectionArray;
    }
}

#pragma mark 获取历史信息
- (void)fetchRoomEarlierMessage
{
    NSLog(@"获取群组内历史消息后，紧接着获取最新消息...");
    
    if (!self.earlierDate) {
        self.earlierDate = [NSDate date];
    }
    
    [self setPredicateForFetchEarlierMessage];
    
    NSError *error = nil;
    if (![self.fetchedEarlierResultsController performFetch:&error]) {
        NSLog(@"获取群组历史信息失败, %@", error);
    }
    else {
        NSIndexPath *indexPath = nil;
        NSArray *fetchedSections = self.fetchedEarlierResultsController.sections;
        
        NSLog(@"获取群组历史消息个数：%lu", (unsigned long)fetchedSections.count);
        if (fetchedSections.count > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedSections lastObject];
            if (sectionInfo) {
                XMPPRoomMessageCoreDataStorageObject *earlierMessage = [[sectionInfo objects] lastObject];
                if (earlierMessage) {
                    self.earlierDate = earlierMessage.localTimestamp;
                }
            }
            
            [self.earlierResultsSectionArray addObjectsFromArray:fetchedSections];
            
            // 合并当前聊天数组和历史数组
            [self mergeAllFetchedResults];
            
            sectionInfo = [fetchedSections firstObject];
            if ([sectionInfo numberOfObjects] > 0) {
                indexPath = [NSIndexPath indexPathForRow:[sectionInfo numberOfObjects] - 1 inSection:fetchedSections.count - 1];
            }
            [(RACSubject *)self.fetchRoomEarlierSignal sendNext:indexPath];
        }
    }
    // 获取完历史消息，再获取最新消息，这样有新消息时，自动fetch
    [self fetchRoomLaterMessage];
}

#pragma mark 获取最新信息
- (void)fetchRoomLaterMessage
{
    if (!self.laterDate) {
        self.laterDate = [NSDate date];
    }
    
    [self setPredicateForFetchLaterMessage];
    
    NSError *error = nil;
    if (![self.fetchedLaterResultsController performFetch:&error]) {
        NSLog(@"获取最新消息失败, %@", error);
    }
    else {
        NSLog(@"获取群组最新消息个数：%lu", (unsigned long)self.fetchedLaterResultsController.sections.count);
        
        if (self.fetchedLaterResultsController.sections.count > 0) {
            [(RACSubject *)self.fetchRoomLaterSignal sendNext:nil];
            
            //更新时间和查询条件
            [self updateFetchLaterDate];
            [self setPredicateForFetchLaterMessage];
        }
    }
}


/////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
/////////////////////////////////////////////////////////////////////////////////

#pragma mark 设置谓词获取更早信息
- (void)setPredicateForFetchEarlierMessage
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"roomJIDStr = '%@'", self.groupJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"%K < %@", @"localTimestamp", self.earlierDate];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedEarlierResultsController.fetchRequest setPredicate:predicate];
}

#pragma mark 设置谓词用于获取之后的信息
- (void)setPredicateForFetchLaterMessage
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"roomJIDStr = '%@'", self.groupJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"localTimestamp > %@", self.laterDate];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedLaterResultsController.fetchRequest setPredicate:predicate];
}

#pragma mark 获取历史消息
- (NSFetchedResultsController *)fetchedEarlierResultsController
{
    NSLog(@"获取群组历史消息NSFetched");
    
    if (_fetchedEarlierResultsController == nil) {
        NSManagedObjectContext *model = [[XMPPManager sharedManager] managedObjectContext_room];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomMessageCoreDataStorageObject" inManagedObjectContext:model];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchLimit:10];
        
        _fetchedEarlierResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:model sectionNameKeyPath:@"sectionIdentifier" cacheName:nil];
    }
    return _fetchedEarlierResultsController;
}


#pragma mark 获取最新的消息
- (NSFetchedResultsController *)fetchedLaterResultsController
{
    NSLog(@"获取群组最新消息NSFetched");
    
    if (_fetchedLaterResultsController == nil) {
        NSManagedObjectContext *model = [[XMPPManager sharedManager] managedObjectContext_room];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPRoomMessageCoreDataStorageObject" inManagedObjectContext:model];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchLimit:10];
        
        _fetchedLaterResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:model sectionNameKeyPath:@"sectionIdentifier" cacheName:nil];
        
        [_fetchedLaterResultsController setDelegate:self];
    }
    return _fetchedLaterResultsController;
}

#pragma mark 内容变化
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"控制器内容发生变化，合并群组历史消息和当前消息...");
    [self mergeAllFetchedResults];
    [(RACSubject *)self.fetchRoomLaterSignal sendNext:nil];
    [self updateFetchLaterDate];
    [self setPredicateForFetchLaterMessage];
}


#pragma mark 获取真实Section数目
- (NSInteger)getRealSection:(NSInteger)section
{
    return [self numberOfSections] - section - 1;
}


///////////////////////////////////////////////////////////////////
#pragma mark DataSource
///////////////////////////////////////////////////////////////////

#pragma mark section数目
- (NSInteger)numberOfSections
{
    return [self.totalResultsSectionArray count];
}

#pragma mark 每个消息的时间
- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> theSection = [self.totalResultsSectionArray objectAtIndex:[self getRealSection:section]];
    NSString *dateString = [theSection name];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *date = [formatter dateFromString:dateString];
    
    return [date formatChatMessageDate];
}


- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.totalResultsSectionArray [[self getRealSection:section]];
    return [sectionInfo numberOfObjects];
}


- (XMPPRoomMessageCoreDataStorageObject *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.totalResultsSectionArray [[self getRealSection:indexPath.section]];
    NSInteger realRow = [sectionInfo numberOfObjects] - indexPath.row - 1;
    
    return [sectionInfo objects][realRow];
}


-(void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.totalResultsSectionArray[[self getRealSection:indexPath.section]];
    NSInteger realRow = [sectionInfo numberOfObjects] - indexPath.row - 1;      // section 对应的object还是原数据
    NSManagedObject *object =  [sectionInfo objects][realRow];
    
    NSManagedObjectContext *context = [self.fetchedLaterResultsController managedObjectContext];
    if (object) {
        [context deleteObject:object];
        
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSLog(@"未解决的错误 %@, %@", error, [error userInfo]);
        }
    }
}



@end
