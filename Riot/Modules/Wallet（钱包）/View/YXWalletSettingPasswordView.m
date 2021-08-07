//
//  YXWalletSettingPasswordView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingPasswordView.h"
#import "YLPasswordInputView.h"
@interface YXWalletSettingPasswordView ()<YLPasswordInputViewDelegate>
@property (nonatomic , strong)YLPasswordInputView *passwordView;
@property (nonatomic , strong)UILabel *nextLabel;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *tipLabel;
@property (nonatomic , strong)UILabel *errorLabel;
@end
@implementation YXWalletSettingPasswordView


#pragma mark - setter and getters

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"设置你的钱包密码";
        _titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
        _titleLabel.textColor = WalletColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"初次使用请设置您的钱包密码";
        _desLabel.font = [UIFont systemFontOfSize: 12];
        _desLabel.textColor = RGB(153, 153, 153);
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

- (YLPasswordInputView *)passwordView{
    if (!_passwordView) {
        _passwordView = [[YLPasswordInputView alloc] init];
        _passwordView.delegate = self;
        [_passwordView updateWithConfigure:^(YLPasswordInputViewConfigure * _Nonnull configure) {
            configure.rectColor = RGBA(255,160,0,1);
            configure.spaceMultiple = 1.0;
        }];;
    }
    return _passwordView;
}

-(UILabel *)errorLabel{
    if (!_errorLabel) {
        _errorLabel = [[UILabel alloc]init];
        _errorLabel.numberOfLines = 0;
        _errorLabel.text = @"两次输入的密码不一致";
        _errorLabel.font = [UIFont systemFontOfSize:12.0];
        _errorLabel.textColor = RGBA(255,60,0,1);
        _errorLabel.textAlignment = NSTextAlignmentCenter;
        _errorLabel.hidden = YES;
    }
    return _errorLabel;
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.text = @"用于支付或者特殊操作的验证";
        _tipLabel.font = [UIFont systemFontOfSize:12.0];
        _tipLabel.textColor = WalletColor;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"下一步";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = WalletColor;
        _nextLabel.textColor = kWhiteColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    if (self.touchBlock) {
        self.touchBlock();
    }
}



- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.desLabel];
    [self addSubview:self.errorLabel];
    [self addSubview:self.passwordView];
    [self addSubview:self.tipLabel];
    [self addSubview:self.nextLabel];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(12);;
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(14);
    }];
    
    [self.passwordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(42);
        make.width.mas_equalTo(42 * 6.0 + 50);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(49);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.errorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.bottom.mas_equalTo(self.passwordView.mas_top).offset(-14);
    }];
    
    [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.passwordView.mas_bottom).offset(14);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(38);
        make.right.mas_equalTo(-38);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(0);
    }];
    
}

#pragma mark - YLPasswordInputViewDelegate

/**输入改变*/
- (void)passwordInputViewDidChange:(YLPasswordInputView *)passwordInputView{
    
}

/**点击删除*/
- (void)passwordInputViewDidDeleteBackward:(YLPasswordInputView *)passwordInputView{
    
}

/**输入完成*/
- (void)passwordInputViewCompleteInput:(YLPasswordInputView *)passwordInputView{
    
}

/**开始输入*/
- (void)passwordInputViewBeginInput:(YLPasswordInputView *)passwordInputView{
    
}

/**结束输入*/
- (void)passwordInputViewEndInput:(YLPasswordInputView *)passwordInputView{
    self.password = passwordInputView.text;
}

#pragma mark - response click

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self endEditing:YES];
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text = title;
}

-(void)setDes:(NSString *)des{
    _des = des;
    _desLabel.text = des;
}

-(void)setShowError:(BOOL)showError{
    _showError = showError;
    _errorLabel.hidden = !showError;
}


-(void)setError:(NSString *)error{
    _error = error;
    _errorLabel.text = error;
}

-(void)setNextText:(NSString *)nextText{
    _nextText = nextText;
    _nextLabel.text = nextText;
}

@end
