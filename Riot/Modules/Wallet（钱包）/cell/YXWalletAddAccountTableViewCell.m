//
//  YXWalletAddAccountTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountTableViewCell.h"
 
@interface YXWalletAddAccountTableViewCell ()
@property (nonatomic , strong)UIImageView *bgImageIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@end

@implementation YXWalletAddAccountTableViewCell

-(UIImageView *)bgImageIcon{
   if (!_bgImageIcon){
       _bgImageIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"zhifubao_add"]];
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
       _titleLabel.text = @"银行卡";
       _titleLabel.font = [UIFont boldSystemFontOfSize: 20];
       _titleLabel.textColor = [UIColor whiteColor];
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
    [self.contentView addSubview:self.bgImageIcon];
    [self.contentView addSubview:self.titleLabel];
    
    [self.bgImageIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(0);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.left.mas_equalTo(81);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(20);
    }];
}

-(void)setupCellWithRowData:(NSString *)rowData{
    _bgImageIcon.image = [UIImage imageNamed:rowData];
    
    if ([rowData isEqualToString:@"card_add"]) {
        self.titleLabel.text = @"银行卡";
    }else if ([rowData isEqualToString:@"zhifubao_add"]){
        self.titleLabel.text = @"支付宝";
    }else if ([rowData isEqualToString:@"wechat_add"]){
        self.titleLabel.text = @"微信";
    }
}

@end
