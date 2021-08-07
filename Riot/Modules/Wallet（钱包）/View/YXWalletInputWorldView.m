// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "YXWalletInputWorldView.h"

@interface YXWalletInputWorldView ()<UITextViewDelegate>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UITextView *textView;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *nextLabel;
@end

@implementation YXWalletInputWorldView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kClearColor;
    }
    return _bgView;
}

-(UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc]init];
        _textView.layer.cornerRadius = 10;
        _textView.clipsToBounds = YES;
        _textView.textColor = UIColor51;
        _textView.font = [UIFont fontWithName:@"PingFang SC" size: 14];
        _textView.textAlignment = NSTextAlignmentLeft;
    }
    return _textView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"注意：助记词是用户钱包的唯一标识，不能分享给他人，严格保密。掌握该助记词的用户即可控制该钱包。";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = kWhiteColor;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"下一个";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = kWhiteColor;
        _nextLabel.textColor = WalletColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    if (self.nextBlock) {
        self.nextBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = WalletColor;
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        [self setupUI];

    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.textView];
    
    [self addSubview:self.desLabel];
    [self addSubview:self.nextLabel];
    
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(150);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(13);
        make.bottom.mas_equalTo(-13);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.textView.mas_bottom).offset(30);
        make.height.mas_equalTo(40);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-23);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
}

-(void)textViewDidChange:(UITextView *)textView{
    self.helpWorld = textView.text;
}

@end
