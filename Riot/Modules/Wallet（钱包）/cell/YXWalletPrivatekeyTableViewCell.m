//
//  YXWalletPrivatekeyTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletPrivatekeyTableViewCell.h"

@interface YXWalletPrivatekeyTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@end

@implementation YXWalletPrivatekeyTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.backgroundColor = kWhiteColor;
        _bgView.layer.cornerRadius = 10;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"地址1：";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = RGB(51, 51, 51);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 2;
        _desLabel.text = @"Sa8GTwUTJg3kvhWVFAec4UV2PB7exp9AHd";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = RGB(170, 170, 170);
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
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
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(0);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(24);
        make.left.mas_equalTo(16);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(14);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(14);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
    }];
}

-(void)setupCellWithRowData:(NSString *)rowData{
    self.desLabel.text = rowData;
}

@end
