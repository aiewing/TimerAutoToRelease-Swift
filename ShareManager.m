//
//  ShareManager.m
//  QKiOS
//
//  Created by Aiewing on 2019/5/28.
//  Copyright © 2019 qingka. All rights reserved.
//

#import "ShareManager.h"
#import "QKStationShareVC.h"
#import "HttpSharePtl.h"
#import "JMShortAudio.h"
#import "JMPublish.h"

@implementation ShareManager

+ (void)pushToStationShareVCWithContents:(JMContents *)contents currentVC:(UIViewController *)currentVC {
    QKStationShareVC *vc = [[QKStationShareVC alloc] init];
    JMContents *content = [[JMContents alloc] init];
    content.type = ContentsShortAudioType;
    JMShortAudio *model = [[JMShortAudio alloc] init];
    JMPublish *model1 = [[JMPublish alloc] init];
    model1.content = @"fdsfdsfdsfdsffdsfdsffdsfdsfdsfdsfdssv";
    model.publish = model1;
    content.shortAudio = model;
    vc.dataContents = content;
    [currentVC.navigationController pushViewController:vc animated:YES];
}

+ (void)shareToDynamicWithUid:(NSNumber *)uid
                  description:(NSString *)des
                     contents:(JMContents *)contents
                      success:(void(^)(void))success
                      failure:(void(^)(void))failure {
    success();
    [HttpSharePtl shareToDynamicWithUid:uid description:des shareType:@1 shareId:@1 success:^(NSDictionary *dict) {
        
    } failure:^(NSInteger code, NSString *message) {
        
    }];
}

@end
