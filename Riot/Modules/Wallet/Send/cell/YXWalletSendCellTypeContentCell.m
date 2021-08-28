//
//  YXWalletSendCellTypeContentCell.m
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendCellTypeContentCell.h"
#import "YXWalletSendModel.h"
@interface YXWalletSendCellTypeContentCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *tipLabel;
@end

@implementation YXWalletSendCellTypeContentCell

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


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"交易类型";
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
        _desLabel.text = @"转账";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.text = @"";
        _tipLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _tipLabel.textColor = UIColor153;
        _tipLabel.textAlignment = NSTextAlignmentRight;
    }
    return _tipLabel;
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
    
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.tipLabel];
    [self.bgView addSubview:self.lineView];
    

    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];

    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(16);
        make.width.mas_equalTo(80);
        make.top.mas_equalTo(30);
        make.left.mas_equalTo(15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(15);
    }];
    
    [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.centerY.mas_equalTo(self.desLabel.mas_centerY);
        make.right.mas_equalTo(-15);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
 
}

-(void)setupCellWithRowData:(YXWalletSendModel *)rowData{
    YXWalletSendDataInfo *sendInfo = rowData.sendDataInfo;
    self.titleLabel.text = rowData.title;
    if ([rowData.title isEqualToString:@"接收地址"]) {
        self.desLabel.text = sendInfo.addr;
    }else if ([rowData.title isEqualToString:@"手续费"]) {
        self.desLabel.text = [NSString stringWithFormat:@"%.2f%%",sendInfo.fees * 100];
    }else if ([rowData.title isEqualToString:@"交易单号"]) {
        if ([rowData.sendDataInfo.action isEqualToString:@"pending"]) {//待处理
            self.desLabel.text = sendInfo.txId;
        }else{
            self.desLabel.text = sendInfo.txHash;
        }
      
    }else{
        self.desLabel.text = rowData.content;
        self.tipLabel.text = rowData.desc;
    }

}

@end
