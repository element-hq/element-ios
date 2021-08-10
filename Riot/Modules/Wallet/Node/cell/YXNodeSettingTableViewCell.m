//
//  YXNodeSettingTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeSettingTableViewCell.h"

@interface YXNodeSettingTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIView *lineView;
@end
@implementation YXNodeSettingTableViewCell


-(UIView *)lineView{
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
        _titleLabel.text = @"【未备注】23axza1e1zx...daczxc112";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor153;
    }
    return _titleLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.lineView];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.centerY.mas_equalTo(self.mas_centerY);
    }];

    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
}

-(void)setModel:(YXNodeConfigDataItem *)model{
    _model = model;
    _titleLabel.text = model.txid;
}

-(void)setNodeInfoModel:(YXNodeListdata *)nodeInfoModel{
    _nodeInfoModel = nodeInfoModel;
    _titleLabel.text = [NSString stringWithFormat:@"IP:%@\n%@",nodeInfoModel.ip,nodeInfoModel.genkey];
}

@end
