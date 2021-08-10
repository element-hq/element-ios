//
//  YXNodeDetailTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailTableViewCell.h"
#import "YXNodeDetailModel.h"
@interface YXNodeDetailTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXNodeDetailTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
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
        _titleLabel.text = @"节点状态";
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
        _desLabel.text = @"运行准备中";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.lineView];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(10);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(8);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
    
}

-(void)setupCellWithRowData:(YXNodeDetailModel *)rowData{
    self.titleLabel.text = rowData.title;
    self.desLabel.text = rowData.desc;
}


@end
