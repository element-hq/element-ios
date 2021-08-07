//
//  YXWalletTipCloseView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletTipCloseView.h"

@interface YXWalletTipCloseView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cloaseBtn;
@property (nonatomic, strong) UIView *touchView;
@end

@implementation YXWalletTipCloseView

-(UIView *)touchView{
    if (!_touchView) {
        _touchView = [[UIView alloc]init];
        _touchView.backgroundColor = kClearColor;
        [_touchView mm_addTapGestureWithTarget:self action:@selector(cloaseBtnAction)];
    }
    return _touchView;
}


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"请注意周围环境，以免私钥泄漏。";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = RGBA(255,60,0,1);
        _titleLabel.textAlignment = NSTextAlignmentCenter;

    }
    return _titleLabel;
}


-(UIButton *)cloaseBtn{
    if (!_cloaseBtn) {
        _cloaseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cloaseBtn setImage:[UIImage imageNamed:@"close_red"] forState:UIControlStateNormal];
        [_cloaseBtn addTarget:self action:@selector(cloaseBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cloaseBtn;
}

- (void)cloaseBtnAction{
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RGBA(247,227,221,1);
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.titleLabel];
    [self addSubview:self.touchView];
    [self addSubview:self.cloaseBtn];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.right.mas_equalTo(-30);
        make.left.mas_equalTo(30);
    }];
    
    [self.touchView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.offset(0);
        make.width.mas_equalTo(30);
    }];
    
    [self.cloaseBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.right.mas_equalTo(-15);
        make.width.mas_equalTo(11);
        make.height.mas_equalTo(11);
    }];
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text = title;
 
}

@end
