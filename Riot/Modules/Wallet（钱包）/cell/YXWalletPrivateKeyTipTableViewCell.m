//
//  YXWalletPrivateKeyTipTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletPrivateKeyTipTableViewCell.h"
 
@interface YXWalletPrivateKeyTipTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@end

@implementation YXWalletPrivateKeyTipTableViewCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"注意：该钱包存在无数个钱包地址，点击下一个即可查看下一个地址私钥。";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = WalletColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(38);
        make.right.mas_equalTo(-38);
    }];
}

-(void)setupCellWithRowData:(NSString *)rowData{
    _titleLabel.text = rowData;
}


@end
