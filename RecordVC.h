//
//  RecordVC.h
//  QKiOS
//
//  Created by syxiaqj on 15/6/9.
//  Copyright (c) 2015年 qingka. All rights reserved.
//

#import <QKRootUIViewLib/QKRootUIViewLib.h>
#import "QKBaseChildViewController.h"

@interface RecordVC : QKBaseChildViewController

/**
 忽略未读消息
 */
- (void)clearAllUnreadMessages;

/**
 加载数据库的record数据
 */
- (void)readyToRefreshRecodData;

@end
