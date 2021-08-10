//
//  YXWalletAccountTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAccountTableViewCell.h"
#import "YXWalletPaymentAccountModel.h"

extern NSString *const kYXWalletAccountSettingDefault;

@interface YXWalletAccountTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIImageView *bgImageIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *typeLabel;
@property (nonatomic , strong)UILabel *numLabel;
@property (nonatomic , strong)YXWalletPaymentAccountRecordsItem *rowData;
@end

@implementation YXWalletAccountTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 10;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

-(UIImageView *)bgImageIcon{
   if (!_bgImageIcon){
       _bgImageIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"bankcard_details"]];
       _bgImageIcon.contentMode = UIViewContentModeScaleAspectFill;
       _bgImageIcon.layer.masksToBounds = YES;
       _bgImageIcon.layer.cornerRadius = 10;
   }
   return _bgImageIcon;
}

-(UILabel *)titleLabel{
   if (!_titleLabel) {
       _titleLabel = [[UILabel alloc]init];
       _titleLabel.numberOfLines = 0;
       _titleLabel.text = @"中国银行";
       _titleLabel.font = [UIFont boldSystemFontOfSize: 20];
       _titleLabel.textColor = [UIColor whiteColor];
       _titleLabel.textAlignment = NSTextAlignmentLeft;
   }
   return _titleLabel;
}

-(UILabel *)desLabel{
   if (!_desLabel) {
       _desLabel = [[UILabel alloc]init];
       _desLabel.numberOfLines = 0;
       _desLabel.text = @"默认收款方式";
       _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
       _desLabel.textColor = [UIColor whiteColor];
       _desLabel.textAlignment = NSTextAlignmentRight;
       YXWeakSelf
       [_desLabel addTapAction:^(UITapGestureRecognizer * _Nonnull sender) {
           [weakSelf routerEventForName:kYXWalletAccountSettingDefault paramater:weakSelf.rowData];
       }];
   }
   return _desLabel;
}

-(UILabel *)typeLabel{
   if (!_typeLabel) {
       _typeLabel = [[UILabel alloc]init];
       _typeLabel.numberOfLines = 0;
       _typeLabel.text = @"储蓄卡";
       _typeLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
       _typeLabel.textColor = [UIColor whiteColor];
       _typeLabel.textAlignment = NSTextAlignmentLeft;
   }
   return _typeLabel;
}

-(UILabel *)numLabel{
   if (!_numLabel) {
       _numLabel = [[UILabel alloc]init];
       _numLabel.numberOfLines = 0;
       _numLabel.text = @"**** **** **** 9941";
       _numLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
       _numLabel.textColor = [UIColor whiteColor];
       _numLabel.textAlignment = NSTextAlignmentLeft;
   }
   return _numLabel;
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
    [self.bgView addSubview:self.bgImageIcon];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.typeLabel];
    [self.bgView addSubview:self.numLabel];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(0);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    
    [self.bgImageIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(18);
        make.left.mas_equalTo(81);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(20);
    }];
    
    [self.typeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(81);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(14);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(81);
        make.top.mas_equalTo(self.typeLabel.mas_bottom).offset(10);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(14);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(18);
        make.right.mas_equalTo(-15);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(15);
    }];
}

- (void)setupCellWithRowData:(YXWalletPaymentAccountRecordsItem *)rowData{
    
    if ([rowData isKindOfClass:YXWalletPaymentAccountRecordsItem.class]) {
        
        _desLabel.hidden = rowData.isDetail;
        
        self.rowData = rowData;
        
        _desLabel.text =  [rowData.acquiescence isEqualToString:@"1"] ? @"默认收款方式" : @"设为默认";
        
        if ([rowData.type isEqualToString:@"1"]) {
            _bgImageIcon.image = [UIImage imageNamed:@"bankcard_details"];
            _titleLabel.text = rowData.options.bank;
            _typeLabel.text = rowData.options.subbranch;
            _numLabel.text = rowData.options.account;
            _typeLabel.hidden = NO;
            _desLabel.hidden = rowData.isDetail;
            [self updateUI:NO];
        }else if  ([rowData.type isEqualToString:@"2"]) {
            _bgImageIcon.image = [UIImage imageNamed:@"wechat_detail"];
            _titleLabel.text = @"微信";
            _numLabel.text = rowData.options.account;
            _typeLabel.hidden = YES;
            [self updateUI:YES];
        }else if  ([rowData.type isEqualToString:@"3"]) {
            _bgImageIcon.image = [UIImage imageNamed:@"zhifubao_detail"];
            _titleLabel.text = @"支付宝";
            _typeLabel.hidden = YES;
            _numLabel.text = rowData.options.account;
            [self updateUI:YES];
        }
    }
    
}

- (void)updateUI:(BOOL)update{
    
    if (update) {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(25);
            make.left.mas_equalTo(81);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(20);
        }];
        
        [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(81);
            make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(15);
            make.width.mas_equalTo(160);
            make.height.mas_equalTo(14);
        }];
    }else{
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(18);
            make.left.mas_equalTo(81);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(20);
        }];
        
        [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(81);
            make.top.mas_equalTo(self.typeLabel.mas_bottom).offset(10);
            make.width.mas_equalTo(160);
            make.height.mas_equalTo(14);
        }];
    }

}

@end
