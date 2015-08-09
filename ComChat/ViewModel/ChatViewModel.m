//
//  ChatViewModel.m
//  ComChat
//
//  Created by D404 on 15/6/6.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "ChatViewModel.h"
#import <RACSubject.h>
#import "XMPPManager.h"
#import "NSDate+IM.h"
#import "Macros.h"
#import "ResourceManager.h"
#import <MBProgressHUD.h>
#import <ReactiveCocoa.h>
#import "UIViewAdditions.h"
#import <ASIHTTPRequest/ASIFormDataRequest.h>
#import "XMPPMessageArchiving_Message_CoreDataObject+ChatMessage.h"


@interface ChatViewModel()<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RACSignal *fetchLaterSignal;
@property (nonatomic, strong) RACSignal *fetchEarlierSignal;

@property (nonatomic, strong) NSFetchedResultsController *fetchedEarlierResultsController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedLaterResultsController;

@property (nonatomic, strong) NSManagedObjectContext *model;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;

@property (nonatomic, strong) NSDate *earlierDate;
@property (nonatomic, strong) NSDate *laterDate;
@property (nonatomic, assign) NSInteger newMessageCount;

@end



@implementation ChatViewModel


#pragma mark 初始化model
- (instancetype)initWithModel:(id)model
{
    if (self = [super init]) {
        self.model = model;
        
        self.fetchLaterSignal = [[RACSubject subject] setNameWithFormat:@"%@fetchLaterSignal", NSStringFromClass([ChatViewModel class])];
        
        self.fetchEarlierSignal = [[RACSubject subject] setNameWithFormat:@"%@fetchEarlierSignal", NSStringFromClass([ChatViewModel class])];
        self.totalResultsSectionArray = [NSMutableArray array];
        self.earlierResultsSectionArray = [NSMutableArray array];
        self.newMessageCount = 0;
    }
    return self;
}


#pragma mark 更新获取到的日期
- (void)updateFetchLaterDate
{
    NSLog(@"更新获取到的日期...");
    if (self.fetchedLaterResultsController.sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedLaterResultsController.sections lastObject];
        if (sectionInfo) {
            XMPPMessageArchiving_Message_CoreDataObject *laterMessage = [[sectionInfo objects] firstObject];
            if (laterMessage) {
                self.laterDate = laterMessage.timestamp;
            }
        }
    }
}

#pragma mark 合并获取到的结果
- (void)mergeAllFetchedResults
{
    NSLog(@"合并获取到的结果...");
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
- (void)fetchEarlierMessage
{
    NSLog(@"获取历史消息后，紧接着获取最新消息...");
    
    if (!self.earlierDate) {
        self.earlierDate = [NSDate date];
    }
    
    [self setPredicateForFetchEarlierMessage];
    
    NSError *error = nil;
    if (![self.fetchedEarlierResultsController performFetch:&error]) {
        NSLog(@"获取历史信息失败, %@", error);
    }
    else {
        NSIndexPath *indexPath = nil;
        NSArray *fetchedSections = self.fetchedEarlierResultsController.sections;
        if (fetchedSections.count > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedSections lastObject];
            if (sectionInfo) {
                XMPPMessageArchiving_Message_CoreDataObject *earlierMessage = [[sectionInfo objects] lastObject];
                if (earlierMessage) {
                    self.earlierDate = earlierMessage.timestamp;
                }
            }
            
            [self.earlierResultsSectionArray addObjectsFromArray:fetchedSections];
            
            // 合并当前聊天数组和历史数组
            [self mergeAllFetchedResults];
            
            sectionInfo = [fetchedSections firstObject];
            if ([sectionInfo numberOfObjects] > 0) {
                indexPath = [NSIndexPath indexPathForRow:[sectionInfo numberOfObjects] - 1 inSection:fetchedSections.count - 1];
            }
            [(RACSubject *)self.fetchEarlierSignal sendNext:indexPath];
        }
    }
    // 获取完历史消息，再获取最新消息，这样有新消息时，自动fetch
    [self fetchLaterMessage];
}

#pragma mark 获取最新信息
- (void)fetchLaterMessage
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
        if (self.fetchedLaterResultsController.sections.count > 0) {
            [(RACSubject *)self.fetchLaterSignal sendNext:nil];
            
            //更新时间和查询条件
            [self updateFetchLaterDate];
            [self setPredicateForFetchLaterMessage];
        }
    }
}

#pragma mark 发送文本消息
- (void)sendMessageWithText:(NSString *)text
{
    if (text.length > 0) {
        NSString *JSONString = [ChatMessageTextEntity JSONStringFromText:text];
        [[XMPPManager sharedManager] sendChatMessage:JSONString
                                                 toJID:self.buddyJID];
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
    NSString *imageName = [ResourceManager generateImageTimeKeyWithPrefix:self.buddyJID.bare];
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
        [[XMPPManager sharedManager] sendChatMessage:JSONString toJID:self.buddyJID.bareJID];
    }];
    [request setFailedBlock: ^{
        NSError *error = request.error;
        NSLog(@"发送图片失败, %@", error);
    }];
    [request setTimeOutSeconds:10000];
    [request startAsynchronous];
    
}

#pragma mark 采用BASE64编码发送语音
- (void)sendMessageWithData:(NSData *)data time:(NSString *)time
{
    NSLog(@"音频发送中...");
    NSString *base64Data = [data base64EncodedStringWithOptions:0];
    NSString *JSONString = [ChatMessageVoiceEntity JSONStringWithAudioData:base64Data time:time];
    [[XMPPManager sharedManager] sendChatMessage:JSONString toJID:self.buddyJID];
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
        [[XMPPManager sharedManager] sendChatMessage:JSONString toJID:self.buddyJID.bareJID];
    }];
    [request setFailedBlock: ^{
        NSError *error = request.error;
        NSLog(@"发送语音失败, %@", error);
    }];
    [request setTimeOutSeconds:10000];
    [request startAsynchronous];
}


/////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
/////////////////////////////////////////////////////////////////////////////////

#pragma mark 设置谓词获取更早信息
- (void)setPredicateForFetchEarlierMessage
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"bareJidStr = '%@'", self.buddyJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"%K < %@", @"timestamp", self.earlierDate];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedEarlierResultsController.fetchRequest setPredicate:predicate];
}

#pragma mark 设置谓词用于获取之后的信息
- (void)setPredicateForFetchLaterMessage
{
    NSPredicate *filterPredicate1 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"bareJidStr = '%@'", self.buddyJID.bare]];
    NSPredicate *filterPredicate2 = [NSPredicate predicateWithFormat:@"timestamp > %@", self.laterDate];
    NSArray *subPredicates = [NSArray arrayWithObjects:filterPredicate1, filterPredicate2, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    [self.fetchedLaterResultsController.fetchRequest setPredicate:predicate];
}

#pragma mark 获取历史消息
- (NSFetchedResultsController *)fetchedEarlierResultsController
{
    NSLog(@"获取历史消息NSFetched");
    if (_fetchedEarlierResultsController == nil) {
        NSManagedObjectContext *model = [[XMPPManager sharedManager] managedObjectContext_messageArchiving];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:model];
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
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
    NSLog(@"获取最新消息NSFetched");
    if (_fetchedLaterResultsController == nil) {
        NSManagedObjectContext *model = [[XMPPManager sharedManager] managedObjectContext_messageArchiving];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:model];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
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
    [self mergeAllFetchedResults];
    [(RACSubject *)self.fetchLaterSignal sendNext:nil];
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


- (XMPPMessageArchiving_Message_CoreDataObject *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.totalResultsSectionArray [[self getRealSection:indexPath.section]];
    NSInteger realRow = [sectionInfo numberOfObjects] - indexPath.row - 1;
    
    return [sectionInfo objects][realRow];
}


-(void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.totalResultsSectionArray[[self getRealSection:indexPath.section]];
    NSInteger realRow = [sectionInfo numberOfObjects] - indexPath.row - 1;// section 对应的object还是原数据
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
