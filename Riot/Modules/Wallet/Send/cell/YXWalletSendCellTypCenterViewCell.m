//
//  YXWalletSendCellTypCenterViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendCellTypCenterViewCell.h"

@interface YXWalletSendCellTypCenterViewCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *leftView;
@property (nonatomic , strong)UIView *rightView;
@property (nonatomic , strong)UIView *lineView;

@end

@implementation YXWalletSendCellTypCenterViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}


-(UIView *)rightView{
    if (!_rightView) {
        _rightView = [[UIView alloc]init];
        _rightView.layer.cornerRadius = 15;
        _rightView.clipsToBounds = YES;
        _rightView.backgroundColor = kBgColor;
    }
    return _rightView;
}
-(UIView *)leftView{
    if (!_leftView) {
        _leftView = [[UIView alloc]init];
        _leftView.layer.cornerRadius = 15;
        _leftView.clipsToBounds = YES;
        _leftView.backgroundColor = kBgColor;
    }
    return _leftView;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}



- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = kBgColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
   
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.leftView];
    [self.contentView addSubview:self.rightView];
    [self.bgView addSubview:self.lineView];

    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.height.mas_equalTo(1);
    }];

    [self.leftView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(30);
    }];
    
    [self.rightView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(30);
    }];
    
}



@end
