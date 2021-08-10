//
//  YXWalletSendCellTypBottomViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendCellTypBottomViewCell.h"

#import "YXWalletSendModel.h"
@interface YXWalletSendCellTypBottomViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *bottombgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;

@end

@implementation YXWalletSendCellTypBottomViewCell

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
        _titleLabel.text = @"创建时间";
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
        _desLabel.text = @"2020-06-24 11:30:25";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentRight;
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
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.desLabel];
    [self.bottombgView mas_remakeConstraints:^(MASConstraintMaker *make) {
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

    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(16);
        make.width.mas_equalTo(80);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.left.mas_equalTo(15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.right.mas_equalTo(-30);
    }];
 
}

-(void)setupCellWithRowData:(YXWalletSendModel *)rowData{
    YXWalletSendDataInfo *sendInfo = rowData.sendDataInfo;
    self.desLabel.text = sendInfo.coinDate;
}

@end
