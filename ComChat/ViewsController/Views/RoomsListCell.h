//
//  RoomsListCell.h
//  ComChat
//
//  Created by D404 on 15/6/12.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoomsListCell : UITableViewCell

- (BOOL)shouldUpdateCellWithObject:(id)object;
- (BOOL)shouldUpdateCellWithRoomsObject:(id)object;
- (BOOL)shouldUpdateCellWithSearchObject:(id)object;

@end
