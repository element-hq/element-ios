//
//  YXWalletSendNextTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendNextTableViewCell.h"
#import "YXWalletSendModel.h"
extern NSString *const kEndEditFieldTextNotification;
extern NSString *const kYXWalletSendNextAction;

@interface YXWalletSendNextTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *topbgView;
@property (nonatomic , strong)UILabel *nextLabel;
@end

@implementation YXWalletSendNextTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

-(UIView *)topbgView{
    if (!_topbgView) {
        _topbgView = [[UIView alloc]init];
        _topbgView.backgroundColor = kWhiteColor;
    }
    return _topbgView;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditFieldTextNotification object:nil];
    [self routerEventForName:kYXWalletSendNextAction paramater:nil];
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
    
    [self.contentView addSubview:self.topbgView];
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.nextLabel];
    
    [self.topbgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-30);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
    
}



@end
