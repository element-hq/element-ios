//
//  YXWalletSettingItemTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingItemTableViewCell.h"
#import "YXWalletSettingModel.h"
@interface YXWalletSettingItemTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIImageView *rightIcon;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXWalletSettingItemTableViewCell
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
        _titleLabel.text = @"收款账户";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = RGB(102, 102, 102);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"未设置";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = RGB(170, 170, 170);
        _desLabel.textAlignment = NSTextAlignmentRight;
        _desLabel.hidden = YXWalletPasswordManager.sharedYXWalletPasswordManager.isHavePassword;
    }
    return _desLabel;
}

- (UIImageView *)rightIcon{
    if (!_rightIcon){
        _rightIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"setting_next"]];
        _rightIcon.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _rightIcon;
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
    [self.contentView addSubview:self.rightIcon];
    [self.contentView addSubview:self.lineView];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(120);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-36);
        make.height.mas_equalTo(14);
        make.width.mas_equalTo(120);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.rightIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(8);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
}

-(void)setupCellWithRowData:(YXWalletSettingModel *)rowData{
    self.titleLabel.text = rowData.title;
    self.desLabel.text = rowData.des;
    
    if (rowData.type == YXWalletSettingTBJLType) {
        self.desLabel.text = [NSString stringWithFormat:@"上次同步 （%@）",rowData.walletModel.modifyDate];
    }
    
    if (rowData.isCenter) {
        self.rightIcon.hidden = YES;
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(20);
            make.centerY.mas_equalTo(self.contentView.mas_centerY);
            make.centerX.mas_equalTo(self.contentView.mas_centerX);
        }];
        self.titleLabel.textColor = WalletColor;
    }else{
        self.rightIcon.hidden = NO;
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(16);
            make.height.mas_equalTo(20);
            make.width.mas_equalTo(120);
            make.centerY.mas_equalTo(self.contentView.mas_centerY);
        }];
        self.titleLabel.textColor = UIColor102;
    }
}

@end
