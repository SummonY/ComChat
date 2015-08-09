//
//  InviteUserCell.h
//  ComChat
//
//  Created by D404 on 15/6/30.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteUserCell : UITableViewCell

@property (nonatomic, assign) BOOL isChecked;

- (void) setChecked:(BOOL)isChecked;
- (BOOL)shouldUpdateCellWithObject:(id)object;


@end
