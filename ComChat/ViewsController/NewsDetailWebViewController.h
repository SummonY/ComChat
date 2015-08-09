//
//  NewsDetailWebView.h
//  ComChat
//
//  Created by D404 on 15/7/24.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsDetailWebViewController : UIViewController

@property (nonatomic, strong) NSString *urlString;

- (id)initWithURL:(NSString *)url;

@end
