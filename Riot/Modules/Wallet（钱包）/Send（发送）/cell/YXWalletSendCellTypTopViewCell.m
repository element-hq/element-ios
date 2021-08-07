//
//  YXWalletSendCellTypTopViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendCellTypTopViewCell.h"
#import "YXWalletSendModel.h"
@interface YXWalletSendCellTypTopViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *bottombgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIImageView *detailSendImage;

@end

@implementation YXWalletSendCellTypTopViewCell

- (UIImageView *)detailSendImage{
    if (!_detailSendImage){
        _detailSendImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"detail_send"]];
        _detailSendImage.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _detailSendImage;
}


-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

-(UIView *)bottombgView{
    if (!_bottombgView) {
        _bottombgView = [[UIView alloc]init];
        _bottombgView.backgroundColor = kWhiteColor;
    }
    return _bottombgView;
}


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"-0.001 VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}


-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"≈￥0.0007";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _desLabel;
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
    
    [self.contentView addSubview:self.bottombgView];
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.detailSendImage];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.desLabel];
    [self.bottombgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(65);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.detailSendImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(66);
        make.height.mas_equalTo(66);
        make.top.mas_equalTo(30);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(16);
        make.top.mas_equalTo(self.detailSendImage.mas_bottom).offset(15);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
    }];
 
}

-(void)setupCellWithRowData:(YXWalletSendModel *)rowData{
    self.titleLabel.text = rowData.title;
    self.desLabel.text = rowData.desc;
    
    if ([rowData.sendDataInfo.action isEqualToString:@"sent"]) {//发送
        _detailSendImage.image = [UIImage imageNamed:@"home_send"];
    }else if ([rowData.sendDataInfo.action isEqualToString:@"received"]) {//接受
        _detailSendImage.image = [UIImage imageNamed:@"home_receive"];
    }else if ([rowData.sendDataInfo.action isEqualToString:@"moved"]) {//内部转移
        _detailSendImage.image = [UIImage imageNamed:@"home_zizhuan"];
    }else if ([rowData.sendDataInfo.action isEqualToString:@"pending"]) {//待处理
        _detailSendImage.image = [UIImage imageNamed:@"home_wait"];
    }
}

@end
