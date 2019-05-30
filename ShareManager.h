//
//  ShareManager.h
//  QKiOS
//
//  Created by Aiewing on 2019/5/28.
//  Copyright © 2019 qingka. All rights reserved.
//

#import "BussinessBaseManager.h"
#import "JMContents.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShareManager : BussinessBaseManager

+ (void)pushToStationShareVCWithContents:(JMContents *)contents currentVC:(UIViewController *)currentVC;

+ (void)shareToDynamicWithUid:(NSNumber *)uid
                  description:(NSString *)des
                        contents:(JMContents *)contents
                      success:(void(^)(void))success
                      failure:(void(^)(void))failure;

@end

NS_ASSUME_NONNULL_END
