//
//  YXAssetsDetailHeadTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXAssetsDetailHeadTableViewCell.h"
#import "YXWalletMyWalletModel.h"
extern NSString *const kYXJumpWalletAssetsDetail;
@interface YXAssetsDetailHeadTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIImageView *nodeIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *countLabel;
@property (nonatomic , strong)UILabel *numLabel;
@property (nonatomic , strong)UILabel *nodeLabel;
@end

@implementation YXAssetsDetailHeadTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        UIView *view = [[UIView alloc] init];
        view.alpha = 1;
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = 20;
        _bgView = view;
        YXWeakSelf
        [_bgView addTapAction:^(UITapGestureRecognizer *sender) {
            [weakSelf routerEventForName:kYXJumpWalletAssetsDetail paramater:nil];
        }];
    }
    return _bgView;
}

- (UIImageView *)nodeIcon{
    if (!_nodeIcon){
        _nodeIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"net_node"]];
        _nodeIcon.contentMode = UIViewContentModeScaleAspectFill;
        _nodeIcon.layer.masksToBounds = YES;
        _nodeIcon.layer.cornerRadius = 20;
    }
    return _nodeIcon;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"总资产（VCL）";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 14];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)nodeLabel{
    if (!_nodeLabel) {
        _nodeLabel = [[UILabel alloc]init];
        _nodeLabel.numberOfLines = 0;
        _nodeLabel.text = @"主节点";
        _nodeLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _nodeLabel.textColor = WalletColor;
        _nodeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nodeLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"￥1991902608.0902";
        _desLabel.font = [UIFont boldSystemFontOfSize:24];
        _desLabel.textColor = [UIColor whiteColor];
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)countLabel{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc]init];
        _countLabel.numberOfLines = 0;
        _countLabel.text = @"≈￥1,487.2816";
        _countLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _countLabel.textColor = [UIColor whiteColor];
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    return _countLabel;
}

-(UILabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [[UILabel alloc]init];
        _numLabel.numberOfLines = 0;
        _numLabel.text = @"最新价：￥0.7469";
        _numLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _numLabel.textColor = [UIColor whiteColor];
        _numLabel.textAlignment = NSTextAlignmentRight;
    }
    return _numLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = WalletColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
  
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.desLabel];
    [self.contentView addSubview:self.countLabel];
    [self.contentView addSubview:self.numLabel];
    
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.nodeIcon];
    [self.bgView addSubview:self.nodeLabel];
   
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(15);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(12);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-100);
    }];
    
    [self.countLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(12);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-15);
        make.right.mas_equalTo(-15);
        make.height.mas_equalTo(12);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(15);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(120);
        make.right.mas_equalTo(20);
    }];
    
    [self.nodeIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(10);
        make.width.height.mas_equalTo(24);
    }];
    
    [self.nodeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(self.nodeIcon.mas_right).offset(10);
        make.height.mas_equalTo(15);
    }];
}

-(void)setupCellWithRowData:(YXWalletMyWalletRecordsItem *)rowData{
    _titleLabel.text = rowData.walletName;
    _desLabel.text = [NSString stringWithFormat:@"≈￥%.4f",rowData.balance];//余额
    
    _countLabel.text = [NSString stringWithFormat:@"≈￥%.2f",rowData.fundValue.floatValue * rowData.balance];
    _numLabel.text = [NSString stringWithFormat:@"￥%@",rowData.fundValue];
}

@end
