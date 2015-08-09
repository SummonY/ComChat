//
//  MessageCellFactory.h
//  ComChat
//
//  Created by D404 on 15/6/8.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MessageCellDelegate;

@interface MessageCellFactory : NSObject

@end

@interface MessageBaseCell : UITableViewCell

@property (nonatomic, weak) id<MessageCellDelegate> delegate;

- (BOOL)shouldUpdateCellWithObject:(id)object;

@end

@interface MessageTextCell : MessageBaseCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end

@interface MessageImageCell : MessageBaseCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@interface MessageVoiceCell : MessageBaseCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@interface MessageAudioCell : MessageBaseCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end

@interface MessageVideoCell : MessageBaseCell

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end

@protocol MessageCellDelegate <NSObject>

@optional
- (void)showUserDetail:(BOOL)isOutgoing;

@end