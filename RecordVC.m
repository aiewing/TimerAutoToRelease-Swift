//
//  RecordVC.m
//  QKiOS
//
//  Created by syxiaqj on 15/6/9.
//  Copyright (c) 2015年 qingka. All rights reserved.
//

#import "RecordVC.h"
#import "MainManager.h"
#import "RecordManager.h"
#import "RecordCell.h"
#import "RMemberCenterVC.h"
#import "RContactAsstVC.h"
#import "RHiVC.h"
#import "RMyWalletVC.h"
#import "FMDBRecord.h"
#import "ChatVC.h"
#import "RLikeVC.h"
#import "RFMVC.h"
#import "RCommentVC.h"
#import "QKYDRedPoint.h"
#import "RDiehardFanVC.h"
#import "RMrBlackCardVC.h"
#import "FloatViewController.h"
#import "QKWebViewController.h"
#import "HttpWebManager.h"
#import "RFootBallBBVC.h"
#import "BackPackVC.h"
#import "QKLoadingView.h"
#import "ChatManager.h"
#import "FMDBLocalParameter.h"
#import "FMDBUpdateManager.h"
#import "QKAlertManager.h"
#import "APShareRadioView.h"
#import "ShareManager.h"

@interface RecordVC () <UITableViewDataSource, UITableViewDelegate, DAContextMenuCellDataSource, DAContextMenuCellDelegate, ReceiveRecordDelegate>

@property (nonatomic, strong) RecordManager *manager;
@property (nonatomic, strong) NSMutableArray <NSMutableArray <FMDBRecord *> *>  *resultRecordList;      // 1.qk团队 2.置顶 3.其它消息
@property (nonatomic, strong) UITableView *recordTableView;     //主表
@property (nonatomic, strong) UILabel *navTitleLbl;     //导航栏标题
@property (nonatomic, strong) UIButton *cleanAllMsgButton;    //清除消息按钮
@property (nonatomic, assign) NSUInteger maxTopedIndex;      //当前置顶的最大Index
@property (nonatomic, strong) NSNumber *lastMid;        //上一次chat的ID
@property (nonatomic, strong) QKLoadingView *loadingView;
@property (nonatomic, strong) FMDBLocalParameter *localParameter;
@property (nonatomic, strong) NSNumber *currentChatVCUid;    // 查看聊天记录页面的id

@property (nonatomic, assign) BOOL didViewShowed;

@property (nonatomic, assign) BOOL needToRefreshTableViewData;

@end

@implementation RecordVC

- (void)readyToRefreshRecodData {
    self.needToRefreshTableViewData = YES;
}

#pragma mark
#pragma mark----- lift cycle -----

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ncbSocketStateChanged:) name:QKSocketStateNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self buildAllViews];
    
    self.didViewShowed = YES;
    
    // 指定消息代理
    [RecordManager defaultManager].recordDelegate = self;
    
    // 初始数据loading处理
    [self.loadingView showInView:self.view updateViewyPoint:StatusBarSafeInsetHeight/2+kQKFitModule(84) centerViewyPoint:-(StatusBarSafeInsetHeight/2+kQKFitModule(84))];
    [self.loadingView loadingText:@"正在加载数据..."];
    
    if (![FMDBUpdateManager ifNeedUpdateFMDBDataBase]) { // 不需要更新数据库
        [self loadRecodData];
    } else {
        [SVProgressHUD showWithStatus:@"数据正在升级，请稍等"];
        @weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [FMDBUpdateManager updateFMDBDataBaseComplete:^{
                [SVProgressHUD dismiss];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    [self loadRecodData];
                });
            }];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //判断APNS是否打开
    NSDate *nowDate = [NSDate qkDate];
    if (nowDate.day != UDShowOpenAPNSTime.day) {
        UIUserNotificationSettings *unSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (unSettings.types == UIUserNotificationTypeNone) {
			[QKAlertManager showWithSuperView:nil title:@"为避免错过喜欢的主播开始直播、发布新节目消息，请开启系统通知。" message:nil cancelTitle:@"再想想" verifyTitle:@"去开启" verifyAction:^(JKAlertAction *action) {
				NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
				if(DeviceSystemVersion < 10.0) {
					[[UIApplication sharedApplication] openURL:settingURL];
				} else {
					[[UIApplication sharedApplication] openURL:settingURL options:@{} completionHandler:nil];
				}
			} configBeforeShow:nil];
			
            UDShowOpenAPNSTime = nowDate;
        }
    }
    
    if (self.needToRefreshTableViewData) {
        [self loadRecodData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[FloatViewController defaultContrlloer] showFloatView];
    
    self.currentChatVCUid = nil;
    [self updateRecordBadge];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark
#pragma mark----- private methods -----

- (void)buildAllViews {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.topTitleView removeFromSuperview];
    [self.view addSubview:self.recordTableView];
    [self.view addSubview:self.navTitleLbl];
    [self.view addSubview:self.cleanAllMsgButton];
    
    if (@available(iOS 11.0, *)) {
        self.recordTableView.estimatedRowHeight = 0;
        self.recordTableView.estimatedSectionHeaderHeight = 0;
        self.recordTableView.estimatedSectionFooterHeight = 0;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (void)p_topLeftBtnClick {
    [self clearAllUnreadMessages];
}

- (void)loadRecodData {
    @weakify(self);
    [RecordManager fetchRankedRecordListWithTimestamp:[NSDate qkTimestamp] complete:^(NSArray *recordList) {
        @strongify(self);
        //组装数据
        [self.resultRecordList removeAllObjects];
//        [self.resultRecordList addObjectsFromArray:recordList];
        self.resultRecordList = [recordList mutableCopy];
        //回调到主线程
        [self.recordTableView reloadData];
        [self.loadingView dismiss];
    }];
}

- (void)updateRecordBadge {
    // 异步线程计算，主线程做红点逻辑
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);
        __block long totalUnreadCount = 0;
        
        [self.resultRecordList enumerateObjectsUsingBlock:^(NSMutableArray<FMDBRecord *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj enumerateObjectsUsingBlock:^(FMDBRecord * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
                totalUnreadCount += record.unReadCount.longValue;
            }];
        }];
        
        FMDBLocalParameter *localParamter = [MainManager localParameter];
        localParamter.recordBadge = @(totalUnreadCount);
        [localParamter bg_saveOrUpdate];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMainVCRecordRedPointNeedShow:(totalUnreadCount != 0)];
        });
    });
}

#pragma mark RecordManagerDelegate

- (void)recordManagerDidRecieveMessege:(FMDBRecord *)message isFromPush:(BOOL)fromPush {
    
    // 页面还没加载，所有的消息都过滤，等viewdidload的loadRecodData:再去加载数据
    if (!self.didViewShowed) { return; }
    
    //重复的消息ID不允许推2次
    if ([self.lastMid integerValue] > 0 && [self.lastMid integerValue] == [message.mid integerValue]) {
        return;
    }
    
    if ([self.resultRecordList.firstObject count] == 0) {
        [self.resultRecordList.firstObject addObject:[RecordManager qkGroupRecord]];
    }
    
    // 收到新消息message
    // 置顶的就置顶
    // 1.如果originerId相同，则覆盖
    // 2.如果是Hi消息，更新未读数字，覆盖
    
    __block BOOL notExitInReusult = YES;
    @weakify(self);
    [self.resultRecordList enumerateObjectsUsingBlock:^(NSMutableArray<FMDBRecord *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        
        [obj enumerateObjectsUsingBlock:^(FMDBRecord * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([message.originerID isEqualToNum:record.originerID]) {
                notExitInReusult = NO;
                FMDBRecord *tempRecord = record;
                [obj removeObject:record];
                
                tempRecord.timestamp = message.timestamp;
                tempRecord.content = message.content;
                
                if ([tempRecord.originerID isEqualToNum:self.currentChatVCUid]) { // 当前已经跳转到chatvc的时候，相同uid的未读数不变
                    
                    if ([tempRecord.originerID isEqualToNum:@(SysAct_ID_Hi)]) { // Hi消息会继续加1，在RHiVC控制
                        tempRecord.addUnReadCount = fromPush? @1 : @0;
                    } else {
                        tempRecord.addUnReadCount = @0;
                    }
                    
                } else {
                    tempRecord.addUnReadCount = fromPush? @1 : @0;
                }
                
                [obj insertObject:tempRecord atIndex:0];
                *stop = YES;
            }
            
        }];
    }];
    
    if (notExitInReusult) { // 如果是新消息，直接插入到最后
        [self.resultRecordList.lastObject insertObject:message atIndex:0];
    }
    
//    //过滤originerID相同消息及Hi消息，更新相关模型
//    FMDBRecord *oldItem = nil;
//    NSUInteger oldItemIndex = 0;
//    NSUInteger hiRecordCount = 0;
//    BOOL isSameTarget = NO;
//    
//    for (FMDBRecord *item in self.resultRecordList) {
//        if ([item.hi integerValue] == 1) {
//            hiRecordCount ++;
//        }
//        // TODO:FMBD Hi
//        if (([item.hi integerValue] == 0 && [item.originerID isEqualToNum:message.originerID])
//            || ([message.hi integerValue] == 1 && hiRecordCount > 0)) {
//            item.timestamp = message.timestamp;
//            item.content = message.content;
//            item.addUnReadCount = fromPush? @1 : @0;
//            isSameTarget = YES;
//            oldItem = item;
//            break;
//        }
//        oldItemIndex ++;
//    }
//    
//    //若果是新的消息
//    if (isSameTarget == NO) {
//        if (self.resultRecordList.count == 0) { // 如果没消息，加一条QK团队消息
//            [self.resultRecordList safeAddObject:[RecordManager qkGroupRecord]];
//        }
//        [self.resultRecordList safeInsertObject:message atIndex:self.maxTopedIndex];
//    } else {
//        if (oldItem.top.boolValue) {      //是置顶消息
//            [self.resultRecordList safeRemoveObjectAtIndex:oldItemIndex];
//            [self.resultRecordList safeInsertObject:oldItem atIndex:1];
//        } else {        //非置顶消息
//            [self.resultRecordList safeInsertObject:oldItem atIndex:self.maxTopedIndex];
//            [self.resultRecordList safeRemoveObjectAtIndex:oldItemIndex+1];
//        }
//    }
    
    self.lastMid = message.mid;
    //回调到主线程
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        [self updateMainVCRecordRedPointNeedShow:YES];
        [self.recordTableView reloadData];
    });
}

- (void)recordManagerDidRecievedMessegeQueryFromDB {
    self.needToRefreshTableViewData = YES;
//    [self loadRecodData];
}

- (void)updateMainVCRecordRedPointNeedShow:(BOOL)show {
    if (show) {
        [MainManager addBadgeWithIndex:TabbarIndexTypeRecord];
    } else {
        [MainManager removeBadgeWithIndex:TabbarIndexTypeRecord];
    }
}

#pragma mark - UITableViewDelegate UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.resultRecordList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultRecordList[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FloatWith3x(204);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QKRecordCell";
    RecordCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[RecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.dataSource = self;
        cell.delegate = self;
    }
    
    [cell buildCell:self.resultRecordList[indexPath.section][indexPath.row] isLasIndexPath:((indexPath.row == self.resultRecordList[indexPath.section].count - 1) && indexPath.section == self.resultRecordList.count - 1) isHiRecordList:NO];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FMDBRecord *record = self.resultRecordList[indexPath.section][indexPath.row];
    //record的设未读数为0
    
    self.currentChatVCUid = record.originerID;
    
    if (record.user.userType.intValue == UserTypeSystem) {   //系统账号
        
        // !!! 新增系统号，在删除的地方也要做逻辑
        
        long long uidValue = record.user.uid.longLongValue;
        if (uidValue == SysAct_ID_QK) {                     // 情咖团队
            [OpenPlatformManager umevent:@"message_click_qkteam"];
            [self pushToChatVCWithUser:record.user];
        } else if (uidValue == SysAct_ID_ContactsAsst) {    // 联系人助手
            [self pushToContactAsstVC];
        } else if (uidValue == SysAct_ID_Hi) {              // Hi
            [self pushToHiVCWithIndexPath:indexPath];
        } else if (uidValue == SysAct_ID_MemberCenter) {    // 消息中心
            [self pushToMemberCenterVC];
        } else if (uidValue == SysAct_ID_MyWallet) {        // 我的钱袋
            [self pushToMyWalletVC];
        } else if (uidValue == SysAct_ID_Like) {            // 赞
            [self pushToLikeVC];
        } else if (uidValue == SysAct_ID_FM) {              // 我的电台
            [self pushToFMVC];
        } else if (uidValue == SysAct_ID_Comment) {         // 评论
            [self pushToCommentVC];
        } else if (uidValue == SysAct_ID_DiehardFan) {      // 铁杆粉丝
            [self pushToDiehardFanVC];
        } else if (uidValue == SysAct_ID_MrBlackCard) {     // 黑卡先生
            [self pushToMrblackCardVC];
        } else if (uidValue == SysAct_ID_FootBallBB) {      // 足球宝贝
            [self pushToFootBallBBVC];
		} else if (uidValue == SysAct_ID_MyBag) {           // 我的背包
			[self pushToMyBagMessage];
		}
        
    } else if (record.user.userType.intValue == UserTypeCommon) {          //普通用户
        [OpenPlatformManager umevent:@"message_click_user_chat"];
        [self pushToChatVCWithUser:record.user];
    }
    
    if (!record.hi.boolValue) { // 非Hi消息，未读数为0，Hi消息未读数在VC处理
        record.unReadCount = @0;
        [record bg_saveOrUpdateAsync:nil];
        [self didSelectedCellExceptHi];
    }
    
    [self.resultRecordList[indexPath.section] safeReplaceObject:record atIndex:indexPath.row];
    //刷新单行
    [self.recordTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

/// 点击Hi以外的cell
- (void)didSelectedCellExceptHi {
    
    [self updateRecordBadge];
    
}

/// 点击hiVC里面的cell
- (void)didSelectedCellInHiVC {
    [self didSelectedCellExceptHi];
}

#pragma mark - DAContextMenuCellDataSource DAContextMenuCellDelegate

- (NSUInteger)numberOfButtonsInContextMenuCell:(DAContextMenuCell *)cell {
    NSIndexPath *indexPath = [self.recordTableView indexPathForCell:cell];
    FMDBRecord *record = self.resultRecordList[indexPath.section][indexPath.row];
    NSUInteger buttonsCount = 0;
    // QK团队不需要删除和置顶菜单
    if (record.user.uid.longLongValue != SysAct_ID_QK) {
        buttonsCount = 2;
    }
    return buttonsCount;
}

- (UIButton *)contextMenuCell:(DAContextMenuCell *)cell buttonAtIndex:(NSUInteger)index {
    RecordCell *tempCell = [cell isKindOfClass:[RecordCell class]] ? (RecordCell *)cell : nil;
    UIButton *button;
    switch (index) {
            case 0: button = tempCell.topBtn; break;
            case 1: button = tempCell.deleteBtn; break;
        default: break;
    }
    return button;
}

- (DAContextMenuCellButtonVerticalAlignmentMode)contextMenuCell:(DAContextMenuCell *)cell alignmentForButtonAtIndex:(NSUInteger)index {
    return DAContextMenuCellButtonVerticalAlignmentModeCenter;
}

- (void)contextMenuCell:(DAContextMenuCell *)cell buttonTappedAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [self.recordTableView indexPathForCell:cell];
    
    if (self.resultRecordList.count == 0) {
        [SVProgressHUD showInfoWithStatus:@"错误代码:-30011,请稍候重试"];
        return;
    }
    
    FMDBRecord *record = self.resultRecordList[indexPath.section][indexPath.row];
    if (index == 0) {   //置顶或取消置顶
        record.top = @(!record.top.boolValue);
        if (record.top.boolValue) { // 操作后：置顶 (讲取消掉数据移到未置顶的第一个)
            [self.resultRecordList[indexPath.section] safeRemoveObjectAtIndex:indexPath.row];
            [self.resultRecordList[1] insertObject:record atIndex:0];
        } else { // 操作后：置顶
            [self.resultRecordList[indexPath.section] safeRemoveObjectAtIndex:indexPath.row];
            [self.resultRecordList.lastObject insertObject:record atIndex:0];
        }
        [RecordManager updateRecordTopStatus:record.top.boolValue withOriginerID:record.originerID];
    } else if (index == 1) {    //删除
        [self deleMessageWithUDid:record.originerID];
        [self.resultRecordList[indexPath.section] removeObjectAtIndex:indexPath.row];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recordTableView reloadData];
    });
}
- (void)contextMenuDidHideInCell:(DAContextMenuCell *)cell {
    
}
- (void)contextMenuDidShowInCell:(DAContextMenuCell *)cell {
    
}
- (void)contextMenuWillHideInCell:(DAContextMenuCell *)cell {
    
}
- (void)contextMenuWillShowInCell:(DAContextMenuCell *)cell {
    
}
- (BOOL)shouldDisplayContextMenuViewInCell:(DAContextMenuCell *)cell{
    return YES;
}

#pragma mark----- 删除聊天信息的同时  需要删除信息 -----

- (void)deleMessageWithUDid:(NSNumber *)originerID {
    
    // 1.删除record
    // 2.删除系统号聊天内容
    // 3.更新角标
    
    // 删除消息record
	[RecordManager deleteRecordWithOriginerID:originerID];
	// 删除聊天消息chat
	[ChatManager deleteChatHistoryWithOriginerID:originerID];
//    //清空记录消息
//    [RecordManager updateRecordContent:@"" withOriginerID:originerID];
//    //发送记录消息
//    [RecordManager sendOneNewRecordContent:@"" withOriginerID:originerID];
//    //发送聊天消息 // TODO:FMBD 下面做什么用？
//    [ChatManager localChatMsgClearChanged:originerID];
}

#pragma mark - SEL

- (void)ncbSocketStateChanged:(NSNotification *)notification {
    SocketState state = [notification.object intValue];
    if (state == SocketStateDisconnect) {
        [self.navTitleLbl setText:@"未连接"];
    } else if (state > SocketStateDisconnect && state < SocketStateAuthSuccess) {
        [self.navTitleLbl setText:@"连接中..."];
    } else if (state == SocketStateAuthSuccess) {
        [self.navTitleLbl setText:@"消息"];
    }
    [self.navTitleLbl sizeToFit];
    self.navTitleLbl.center = CGPointMake(kQKFitModule(15)+_navTitleLbl.width/2.0, StatusBarSafeInsetHeight/2+kQKFitModule(45)+_navTitleLbl.height/2.0);
}

- (void)clearAllUnreadMessages {
    [OpenPlatformManager umevent:@"message_click_ignore_all"];
    // 更新未读数
    [RecordManager clearAllUnReadCount];
    // 更新数据源
    [self loadRecodData];
}

#pragma mark - Pri Method

- (void)pushToMemberCenterVC {
    RMemberCenterVC *vc = [RMemberCenterVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToContactAsstVC {
    RContactAsstVC *vc = [RContactAsstVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToHiVCWithIndexPath:(NSIndexPath *)indexPath {
    RHiVC *vc = [RHiVC new];
    
    @weakify(self);
    [vc updateHiRecordUnreadCount:^(NSNumber *unreadCount) {
        @strongify(self);
        
        FMDBRecord *record = self.resultRecordList[indexPath.section][indexPath.row];
        record.unReadCount = unreadCount;
        [record bg_saveOrUpdate];

        if (unreadCount.longValue == 0) {
//            [self loadRecodData];
            self.needToRefreshTableViewData = YES;
        } else {
            [self.recordTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self didSelectedCellExceptHi];
        }
    }];
    
    [vc clearAllHiRecordBlock:^{
        @strongify(self);
//        [self loadRecodData];
        self.needToRefreshTableViewData = YES;
    }];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToMyWalletVC {
    RMyWalletVC *vc = [RMyWalletVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToChatVCWithUser:(FMDBUser *)user {
//    ChatVC *vc = [ChatVC new];
//    vc.desUser = user;
//    [self.navigationController pushViewController:vc animated:YES];
    @weakify(self);
    [APShareRadioView showInView:self.view backgroundUrl:@"" selectItemAction:^(APShareRadioViewItemType type) {
        @strongify(self);
        [ShareManager pushToStationShareVCWithContents:[[NSObject alloc] init] currentVC:self];
    }];

    
}

- (void)pushToLikeVC {
    RLikeVC *vc = [RLikeVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToFMVC {
    RFMVC *vc = [RFMVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToCommentVC {
    RCommentVC *vc = [RCommentVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToDiehardFanVC {
    RDiehardFanVC *vc = [RDiehardFanVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToMrblackCardVC {
    RMrBlackCardVC *vc = [[RMrBlackCardVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToFootBallBBVC {
    RFootBallBBVC *vc = [[RFootBallBBVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)pushToMyBagMessage {
	BackPackVC *back = [[BackPackVC alloc] init];
	[self.navigationController pushViewController:back animated:YES];
}

- (void)pushToQKWebActVC {
    QKWebViewController *vc = [[QKWebViewController alloc] init];
    vc.url = [HttpWebManager shareCourseOpenBoxAct];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Pri Property

- (UITableView *)recordTableView {
    if (!_recordTableView) {
        _recordTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, StatusBarSafeInsetHeight/2+kQKFitModule(84), ScreenWidth, ScreenHeight-kQKFitModule(84)-TabBarHeight-StatusBarSafeInsetHeight/2) style:UITableViewStylePlain];
        _recordTableView.delegate = self;
        _recordTableView.dataSource = self;
        _recordTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _recordTableView.tableFooterView = [UIView new];
        _recordTableView.backgroundColor = [UIColor qkBgColor];
        _recordTableView.separatorColor = [UIColor qkSepLineColor];
    }
    return _recordTableView;
}

- (NSMutableArray<NSMutableArray<FMDBRecord *> *> *)resultRecordList {
    if (!_resultRecordList) {
        _resultRecordList =  [[NSMutableArray alloc] init];
    }
    return _resultRecordList;
}

- (NSUInteger)maxTopedIndex {
    NSUInteger index = 0;
    for (FMDBRecord *record in self.resultRecordList) {
        if ([record.top boolValue]) {
            index ++;
        }
    }
    return index;
}

- (UILabel *)navTitleLbl {
    if (!_navTitleLbl) {
        _navTitleLbl = [UILabel labelWithText:@"连接中..." font:(ScreenWidth >= 375)? kQKFitFontBold(24) : ([UIFont boldSystemFontOfSize:24]) textColor:[UIColor blackColor]];
        [_navTitleLbl sizeToFit];
        _navTitleLbl.center = CGPointMake(kQKFitModule(15)+_navTitleLbl.width/2.0, StatusBarSafeInsetHeight/2+kQKFitModule(45)+_navTitleLbl.height/2.0);
    }
    return _navTitleLbl;
}

- (UIButton *)cleanAllMsgButton {
    if (!_cleanAllMsgButton) {
        _cleanAllMsgButton = [UIButton new];
        [_cleanAllMsgButton setTitle:@"忽略未读" forState:(UIControlStateNormal)];
        [_cleanAllMsgButton addTarget:self action:@selector(clearAllUnreadMessages) forControlEvents:(UIControlEventTouchUpInside)];
        _cleanAllMsgButton.titleLabel.font = (ScreenWidth >= 375)? kQKFitFontNormal(15) : [UIFont systemFontOfSize:15];
        [_cleanAllMsgButton setTitleColor:COLOR_WITH_HEX(0x333333) forState:(UIControlStateNormal)];
        [_cleanAllMsgButton sizeToFit];
        _cleanAllMsgButton.center = CGPointMake(ScreenWidth-kQKFitModule(15)-_cleanAllMsgButton.width/2.0, _navTitleLbl.bottom - _cleanAllMsgButton.height/2.0);
    }
    return _cleanAllMsgButton;
}

- (QKLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [QKLoadingView new];
        _loadingView.backgroundColor = [UIColor whiteColor];
    }
    return _loadingView;
}

@end
