//
//  YXNaviView.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXNaviView.h"
@interface YXNaviView ()
@property (nonatomic, strong) UIButton *leftBarButtonItem;
@property (nonatomic, strong) UIButton *rightBarButtonItem;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *rightLabel;
@end

@implementation YXNaviView

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _titleLabel.textColor = [UIColor colorWithRed:27/255.0 green:27/255.0 blue:27/255.0 alpha:1.0];
        _titleLabel.hidden = YES;
    }
    return _titleLabel;
}

-(UILabel *)rightLabel{
    if (!_rightLabel) {
        _rightLabel = [[UILabel alloc]init];
        _rightLabel.numberOfLines = 0;
        _rightLabel.text = @"兑现记录";
        _rightLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _rightLabel.textColor = WalletColor;
        _rightLabel.hidden = YES;
        YXWeakSelf
        [_rightLabel addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.rightLabelBlock) {
                weakSelf.rightLabelBlock();
            }
        }];
    }
    return _rightLabel;
}


-(UIButton *)leftBarButtonItem{
    if (!_leftBarButtonItem) {
        _leftBarButtonItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBarButtonItem setImage:[UIImage imageNamed:@"back_w"] forState:UIControlStateNormal];
        [_leftBarButtonItem addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBarButtonItem;
}

- (void)backAction{
    if (self.backBlock) {
        self.backBlock();
    }
}

-(UIButton *)rightBarButtonItem{
    if (!_rightBarButtonItem) {
        _rightBarButtonItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBarButtonItem setImage:[UIImage imageNamed:@"home_setting"] forState:UIControlStateNormal];
        [_rightBarButtonItem addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
        _rightBarButtonItem.hidden = YES;
    }
    return _rightBarButtonItem;
}

- (void)moreAction{
    if (self.moreBlock) {
        self.moreBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.leftBarButtonItem];
    [self addSubview:self.rightBarButtonItem];
    [self addSubview:self.rightLabel];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.centerX.mas_equalTo(self.mas_centerX);
        make.bottom.mas_equalTo(-16);
    }];
     
    [self.leftBarButtonItem mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(8);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(StatusSizeH);
    }];
    
    [self.rightBarButtonItem mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-8);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(StatusSizeH);
    }];
    
    [self.rightLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-8);
        make.height.mas_equalTo(18);
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
        make.bottom.mas_equalTo(-16);
    }];
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text = title;
    _titleLabel.hidden = NO;
}

-(void)setTitleColor:(UIColor *)titleColor{
    _titleColor = titleColor;
    _titleLabel.textColor = titleColor;
}

-(void)setShowMoreBtn:(BOOL)showMoreBtn{
    _showMoreBtn = showMoreBtn;
    _rightBarButtonItem.hidden = !showMoreBtn;
}

-(void)setShowBackBtn:(BOOL)showBackBtn{
    _showBackBtn = showBackBtn;
    _leftBarButtonItem.hidden = !showBackBtn;
}

-(void)setLeftImage:(UIImage *)leftImage{
    _leftImage = leftImage;
    [_leftBarButtonItem setImage:leftImage forState:UIControlStateNormal];
}

-(void)setRightImage:(UIImage *)rightImage{
    _rightImage = rightImage;
    [_rightBarButtonItem setImage:rightImage forState:UIControlStateNormal];
}

-(void)setShowRightLabel:(BOOL)showRightLabel{
    _showRightLabel = showRightLabel;
    self.rightLabel.hidden = !showRightLabel;
}

@end
