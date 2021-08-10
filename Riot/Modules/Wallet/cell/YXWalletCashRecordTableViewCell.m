// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "YXWalletCashRecordTableViewCell.h"
#import "YXWalletCashModel.h"
@interface YXWalletCashRecordTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIImageView *titleIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *countLabel;
@property (nonatomic , strong)UILabel *numLabel;
@property (nonatomic , strong)UILabel *statueLabel;
@property (nonatomic , strong)UILabel *tipLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXWalletCashRecordTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        UIView *view = [[UIView alloc] init];
        view.alpha = 1;
        view.backgroundColor = kBgColor;
        _bgView = view;
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

- (UIImageView *)titleIcon{
    if (!_titleIcon){
        _titleIcon = [[UIImageView alloc]initWithImage:FullGray_PLACEDHOLDER_IMG];
        _titleIcon.contentMode = UIViewContentModeScaleAspectFill;
        _titleIcon.layer.masksToBounds = YES;
        _titleIcon.layer.cornerRadius = 17;
    }
    return _titleIcon;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"兑现";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"**** 9941 储蓄卡";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = RGB(170, 170, 170);
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}



-(UILabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [[UILabel alloc]init];
        _numLabel.numberOfLines = 0;
        _numLabel.text = @"2020-06-21 11:47:27";
        _numLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _numLabel.textColor = RGB(170, 170, 170);
        _numLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _numLabel;
}

-(UILabel *)countLabel{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc]init];
        _countLabel.numberOfLines = 0;
        _countLabel.text = @"-100.00";
        _countLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _countLabel.textColor = RGB(170, 170, 170);
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    return _countLabel;
}

-(UILabel *)statueLabel{
    if (!_statueLabel) {
        _statueLabel = [[UILabel alloc]init];
        _statueLabel.numberOfLines = 0;
        _statueLabel.text = @"已完成";
        _statueLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _statueLabel.textColor = RGB(170, 170, 170);
        _statueLabel.textAlignment = NSTextAlignmentRight;
    }
    return _statueLabel;
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.text = @"原因说明：账号错误！请核对支付宝账号！";
        _tipLabel.font = [UIFont fontWithName:@"PingFang SC" size: 10];
        _tipLabel.textColor = RGB(255,60,0);
        _tipLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _tipLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = kWhiteColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.titleIcon];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.numLabel];
    [self.bgView addSubview:self.countLabel];
    [self.bgView addSubview:self.statueLabel];
    [self.bgView addSubview:self.tipLabel];
    [self.bgView addSubview:self.lineView];
   
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.titleIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(15);
        make.left.mas_equalTo(15);
        make.width.height.mas_equalTo(50);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleIcon.mas_top);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(12);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(14);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(10);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(14);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);;
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(14);
    }];
    
    [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.numLabel.mas_bottom).offset(14);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);;
        make.height.mas_equalTo(14);
    }];
    
    [self.statueLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.numLabel.mas_centerY);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(14);
    }];
    
    [self.countLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleIcon.mas_top);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(18);
    }];

    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
    
}

-(void)setupCellWithRowData:(YXWalletCashRecordsItem *)rowData{
    _tipLabel.hidden = YES;
    if (rowData.status == -1) {
        _statueLabel.text = @"兑现失败";
        _titleIcon.image = [UIImage imageNamed:@"jilu_dui_fail"];
        _tipLabel.hidden = NO;
        _tipLabel.text = rowData.message;
    }else if (rowData.status == 0) {
        _statueLabel.text = @"未完成";
        _titleIcon.image = [UIImage imageNamed:@"jilu_not_finished"];
    }else if (rowData.status == 1) {
        _statueLabel.text = @"销毁交易成功";
        _titleIcon.image = [UIImage imageNamed:@"jilu_dui"];
    }else if (rowData.status == 2) {
        _statueLabel.text = @"待审核";
        _titleIcon.image = [UIImage imageNamed:@"jilu_dui_wait"];
    }else if (rowData.status == 3) {
        _statueLabel.text = @"兑现成功";
        _titleIcon.image = [UIImage imageNamed:@"jilu_dui"];
    }
    
    _desLabel.text = _desLabel.text = rowData.message;
    _numLabel.text = rowData.createDate;
    _countLabel.text = rowData.amount;
    
}

@end
