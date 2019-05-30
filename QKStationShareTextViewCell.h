//
//  QKStationShareTextViewCell.h
//  QKiOS
//
//  Created by Aiewing on 2019/5/27.
//  Copyright © 2019 qingka. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ShareTextCb)(NSString *content);

NS_ASSUME_NONNULL_BEGIN

@interface QKStationShareTextViewCell : UITableViewCell

@property (nonatomic, copy) ShareTextCb contentCb;

@end

NS_ASSUME_NONNULL_END
