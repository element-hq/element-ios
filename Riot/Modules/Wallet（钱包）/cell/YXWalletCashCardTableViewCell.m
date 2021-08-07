//
//  YXWalletCashCardTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashCardTableViewCell.h"
#import "YXWalletCashModel.h"
#import "YXWalletPaymentAccountModel.h"
@interface YXWalletCashCardTableViewCell ()
@property (nonatomic , strong) UIView *bgView;
@property (nonatomic , strong) UIImageView *headImageView;
@property (nonatomic , strong) UIImageView *rightIcon;
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UILabel *desLabel;
@property (nonatomic , strong)UIView *lineView;
@end
@implementation YXWalletCashCardTableViewCell


-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}

- (UIImageView *)rightIcon{
    if (!_rightIcon){
        _rightIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"setting_next"]];
        _rightIcon.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _rightIcon;
}

- (UIImageView *)headImageView{
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc]init];
        _headImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headImageView.clipsToBounds = YES;
        _headImageView.image = FullGray_PLACEDHOLDER_IMG;
    }
    return _headImageView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"**** 9941 储蓄卡";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor51;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"中国银行";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = UIColor102;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.bgView];
    
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.rightIcon];
    [self.bgView addSubview:self.headImageView];
    [self.bgView addSubview:self.lineView];
    
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    [self.headImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(50);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headImageView.mas_right).offset(10);
        make.height.mas_equalTo(13);
        make.top.mas_equalTo(9);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headImageView.mas_right).offset(10);
        make.height.mas_equalTo(13);
        make.bottom.mas_equalTo(-9);;
    }];
    
    [self.rightIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(8);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];

}

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:YXWalletCashModel.class]) {
        YXWalletCashModel *model = (YXWalletCashModel *)rowData;
        self.lineView.hidden = !model.showLine;
        
        YXWalletPaymentAccountRecordsItem *accountModel = model.accountModel;
        
        if ([accountModel.type isEqualToString:@"1"]) {
            _headImageView.image = [UIImage imageNamed:@"bank_card"];
            _titleLabel.text = accountModel.options.bank;
            _desLabel.text = accountModel.options.account;
          
        }else if  ([accountModel.type isEqualToString:@"2"]) {
            _headImageView.image = [UIImage imageNamed:@"wechat_pay"];
            _titleLabel.text = @"微信";
            _desLabel.text = accountModel.options.account;
        }else if  ([accountModel.type isEqualToString:@"3"]) {
            _headImageView.image = [UIImage imageNamed:@"zhifub_pay"];
            _titleLabel.text = @"支付宝";
            _desLabel.text = accountModel.options.account;
  
        }
    }
    
   
}


@end
