//
//  YXWalletCashTitleTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashTitleTableViewCell.h"
#import "YXWalletCashModel.h"
 
@interface YXWalletCashTitleTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXWalletCashTitleTableViewCell
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"当前价值";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"￥0.7476";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = UIColor102;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}



- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.desLabel];
    [self.contentView addSubview:self.lineView];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(62);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(90);
        make.height.mas_equalTo(14);
        make.right.mas_equalTo(-16);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
}

-(void)setupCellWithRowData:(YXWalletCashModel *)rowData{
    
    if ([rowData.name isEqualToString:@"当前价值"]) {
        self.titleLabel.text = @"当前价值";
        self.desLabel.text = [NSString stringWithFormat:@"≈￥%.4f",rowData.walletModel.fundValue.floatValue * rowData.walletModel.balance];   
    }else if ([rowData.name isEqualToString:@"手续费"]){
        self.titleLabel.text = @"手续费";
        self.desLabel.text = [NSString stringWithFormat:@"%@%%",rowData.walletModel.cashFee];
    }
}

@end
