//
//  YXAssetsDetailListTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXAssetsDetailListTableViewCell.h"
#import "YXAssetsDetailListModel.h"
@interface YXAssetsDetailListTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIImageView *titleIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *countLabel;
@property (nonatomic , strong)UILabel *numLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXAssetsDetailListTableViewCell

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
        _titleLabel.text = @"待处理交易";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = RGB(102, 102, 102);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"卫生费";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 10];
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
        _numLabel.font = [UIFont fontWithName:@"PingFang SC" size: 10];
        _numLabel.textColor = RGB(170, 170, 170);
        _numLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _numLabel;
}

-(UILabel *)countLabel{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc]init];
        _countLabel.numberOfLines = 0;
        _countLabel.text = @"-100.00 VCL";
        _countLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _countLabel.textColor = RGB(102, 102, 102);
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    return _countLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = kClearColor;
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
    [self.bgView addSubview:self.lineView];
   
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.offset(0);
    }];
    
    [self.titleIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(12);
        make.left.mas_equalTo(10);
        make.width.height.mas_equalTo(34);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleIcon.mas_top);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(12);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(10);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);;
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(14);
    }];
    
    [self.countLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.titleIcon.mas_centerY);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(18);
    }];

    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
    
}

- (void)setupCellWithRowData:(YXAssetsDetailRecordsItem *)rowData{
    if ([rowData.action isEqualToString:@"sent"]) {//发送
        _titleLabel.text = @"已发送";
        _titleIcon.image = [UIImage imageNamed:@"home_send"];
    }else if ([rowData.action isEqualToString:@"received"]) {//接受
        _titleLabel.text = @"已接收";
        _titleIcon.image = [UIImage imageNamed:@"home_receive"];
    }else if ([rowData.action isEqualToString:@"moved"]) {//内部转移
        _titleLabel.text = @"内部转移";
        _titleIcon.image = [UIImage imageNamed:@"home_zizhuan"];
    }else if ([rowData.action isEqualToString:@"pending"]) {//待处理
        _titleLabel.text = @"待处理";
        _titleIcon.image = [UIImage imageNamed:@"home_wait"];
    }
    
    
    _desLabel.text = _desLabel.text = rowData.message;
    _numLabel.text = rowData.coinDate;
    _countLabel.text = [NSString stringWithFormat:@"%@ %@",@(rowData.amount).stringValue,GET_A_NOT_NIL_STRING(rowData.baseSybol)];
}
@end
