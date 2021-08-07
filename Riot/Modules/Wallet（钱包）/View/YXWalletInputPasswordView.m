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

#import "YXWalletInputPasswordView.h"
#import "HWTFCodeView.h"
@interface YXWalletInputPasswordView ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIButton *cloaseBtn;
@property (nonatomic , strong)HWTFCodeView *code1View;
@end

@implementation YXWalletInputPasswordView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 10;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

-(UIButton *)cloaseBtn{
    if (!_cloaseBtn) {
        _cloaseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cloaseBtn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
        [_cloaseBtn addTarget:self action:@selector(cloaseBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cloaseBtn;
}

- (void)cloaseBtnAction{
    self.hidden = YES;
    if (self.cloaseBtnBlock) {
        self.cloaseBtnBlock();
    }
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 1;
        _titleLabel.text = @"密码验证";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _titleLabel.textColor = RGB(33, 33, 33);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 2;
        _desLabel.text = @"请输入钱包密码进行交易";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _desLabel;
}

-(HWTFCodeView *)code1View{
    if (!_code1View) {
        YXWeakSelf
        _code1View = [[HWTFCodeView alloc] initWithCount:6 margin:12];
        _code1View.frame = CGRectMake(0, 0, 280, 40);
        [_code1View setEndEditBlock:^(NSString * _Nonnull code) {
            if (weakSelf.endEditBlock) {
                weakSelf.endEditBlock(code);
            }
        }];
    }
    return _code1View;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RGBA(0, 0, 0, 0.3);
        [self setupUI];

    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.cloaseBtn];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.code1View];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(200);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.cloaseBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.width.mas_equalTo(11);
        make.height.mas_equalTo(11);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(19);
        make.top.mas_equalTo(45);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(55);
        make.right.mas_equalTo(-55);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(15);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.code1View mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(35);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(15);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
}


@end
