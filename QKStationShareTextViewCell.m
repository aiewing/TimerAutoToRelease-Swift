//
//  QKStationShareTextViewCell.m
//  QKiOS
//
//  Created by Aiewing on 2019/5/27.
//  Copyright © 2019 qingka. All rights reserved.
//

#import "QKStationShareTextViewCell.h"
#import "SZTextView.h"

@interface QKStationShareTextViewCell () <UITextViewDelegate>

@property (nonatomic, strong) SZTextView *textView;
@property (nonatomic, strong) UILabel *countLabel;

@end

@implementation QKStationShareTextViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self createUI];
    }
    return self;
}

- (void)createUI {
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.countLabel];
}

- (void)layoutSubviews {
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(10);
        make.top.equalTo(self.contentView).offset(10);
        make.right.equalTo(self.contentView).offset(-10);
        make.bottom.equalTo(self.contentView).offset(-25);
    }];
    
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(self.contentView).offset(-5);
        make.size.mas_equalTo(CGSizeMake(100, 20));
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length >= 200) {
        textView.text = [textView.text substringToIndex:200];
    }
    self.countLabel.text = [NSString stringWithFormat:@"%zd/200", textView.text.length];
    if (self.contentCb) {
        self.contentCb(self.countLabel.text);
    }
}


#pragma mark - Private Property
- (SZTextView *)textView {
    if (!_textView) {
        _textView = [[SZTextView alloc] init];
        _textView.placeholder = @"说点什么吧...";
        _textView.placeholderTextColor = [UIColor lightGrayColor];
        _textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
        _textView.delegate = self;
    }
    return _textView;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.text = @"0/200";
        _countLabel.textAlignment = NSTextAlignmentRight;
        _countLabel.font = [UIFont systemFontOfSize:16];
        _countLabel.textColor = [UIColor lightGrayColor];
    }
    return _countLabel;
}

@end
