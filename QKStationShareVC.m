//
//  QKStationShareVC.m
//  QKiOS
//
//  Created by Aiewing on 2019/5/27.
//  Copyright © 2019 qingka. All rights reserved.
//

#import "QKStationShareVC.h"
#import "QKStationShareTextViewCell.h"
#import "QKStationShareAudioCell.h"
#import "QKStationShareAlbumCell.h"
#import "QKStationShareAskAndAnswerCell.h"
#import "ShareManager.h"
#import "QKDynamicFreshAudioView.h"
#import "JMShortAudio.h"
#import "JMPublish.h"
#import "JMContents.h"
#import "QKStationShareBaseCell.h"

@interface QKStationShareVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *shareTableView;
@property (nonatomic, copy) NSString *shareText;

@end

@implementation QKStationShareVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
    [self registerTableViewCell];
    [self layoutSubViews];
}

- (void)createUI {
    [self createNavagationBar];
    
    if (@available(iOS 11.0, *)) {
        self.shareTableView.estimatedRowHeight = 0;
        self.shareTableView.estimatedSectionHeaderHeight = 0;
        self.shareTableView.estimatedSectionFooterHeight = 0;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.view addSubview:self.shareTableView];
}

- (void)registerTableViewCell {
    [self.shareTableView registerClass:[QKStationShareAlbumCell class] forCellReuseIdentifier:@"QKStationShareAlbumCell"];
    [self.shareTableView registerClass:[QKStationShareTextViewCell class] forCellReuseIdentifier:@"QKStationShareTextViewCell"];
    [self.shareTableView registerClass:[QKStationShareAudioCell class] forCellReuseIdentifier:@"QKStationShareAudioCell"];
}

- (void)layoutSubViews {
    [self.shareTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.topTitleView.mas_bottom);
    }];
}

- (void)createNavagationBar {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[Nav_Title] = @"发布";
    params[Nav_LeftTxt] = @"取消";
    params[Nav_RightTxt] = @"确认";
    [self p_setTopTitleDetail:params];
}

#pragma mark – Override
- (void)p_topRightBtnClick {
    @weakify(self);
    [ShareManager shareToDynamicWithUid:@1 description:self.shareText contents:self.dataContents success:^{
        @strongify(self);
        [self.navigationController popViewControllerAnimated:true];
    } failure:^{
        
    }];
    
}

#pragma mark - Custom Delegates
#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        QKStationShareTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"QKStationShareTextViewCell"];
        @weakify(self);
        cell.contentCb = ^(NSString * _Nonnull content) {
            @strongify(self)
            self.shareText = content;
        };
        return cell;
    } else if (indexPath.row == 1) {
        QKStationShareBaseCell *cell;
        switch (self.dataContents.type) {
            case ContentsShortAudioType:
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"QKStationShareAudioCell"];
            }
                break;
            case ContentsAlbumType:
            case ContentsProgramType:
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"QKStationShareAlbumCell"];
            }
                break;
            case ContentsQAType:
            case ContentsAnswerType:
            case ContentsAnchorLiveType:
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"QKStationShareAskAndAnswerCell"];
                if (!cell) {
                    cell = [[QKStationShareAskAndAnswerCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"QKStationShareAskAndAnswerCell" cellStyle:QKStationShareAskAndAnswerCellStyle_Normal];
                }
            }
            default:
                break;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contents = self.dataContents;
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 130;
    } else if (indexPath.row == 1) {
        switch (self.dataContents.type) {
            case ContentsShortAudioType:
            {
                return [QKStationShareAudioCell heightWithData:self.dataContents.shortAudio];
            }
                break;
            case ContentsAlbumType:
            case ContentsProgramType:
            {
                return 70;
            }
                break;
            case ContentsQAType:
            case ContentsAnswerType:
            case ContentsAnchorLiveType:
            {
                return 90;
            }
            default:
                break;
        }
    }
    return 0;
}

#pragma mark - Private Property
- (UITableView *)shareTableView {
    if (!_shareTableView) {
        _shareTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _shareTableView.delegate = self;
        _shareTableView.dataSource = self;
        _shareTableView.tableFooterView = [[UIView alloc] init];
        _shareTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _shareTableView.scrollEnabled = false;
    }
    return _shareTableView;
}

@end
