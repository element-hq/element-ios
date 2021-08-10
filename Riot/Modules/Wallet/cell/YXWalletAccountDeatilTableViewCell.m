//
//  YXWalletAccountDeatilTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAccountDeatilTableViewCell.h"
#import "YXWalletPaymentAccountModel.h"
@interface YXWalletAccountDeatilTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXWalletAccountDeatilTableViewCell
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
        _titleLabel.text = @"开户行";
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
        _desLabel.text = @"中国银行北京市三里屯天桥支行";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = UIColor51;
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

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:YXWalletPaymentAccountRecordsItem.class]) {
        YXWalletPaymentAccountRecordsItem *model = rowData;
        if ([model.title isEqualToString:@"开户行"]) {
            self.titleLabel.text = model.title;
            self.desLabel.text = model.options.subbranch;
        }
        
        if ([model.title isEqualToString:@"手机号码"]) {
            self.titleLabel.text = model.title;
            self.desLabel.text = model.options.phone;
        }
  
        if ([model.title isEqualToString:@"用户账户"]) {
            self.titleLabel.text = model.title;
            self.desLabel.text = model.options.account;
        }
        
    }
}

@end
