//
//  YXWalletAddTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddTableViewCell.h"
 
extern NSString *const kYXWalletShowAddViewFountion;
@interface YXWalletAddTableViewCell ()
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UIButton *addBtn;
@end

@implementation YXWalletAddTableViewCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"资产";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = RGB(51, 51, 51);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UIButton *)addBtn{
    if (!_addBtn) {
        _addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_addBtn setImage:[UIImage imageNamed:@"home_add.png"] forState:UIControlStateNormal];
        [_addBtn addTarget:self action:@selector(addBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

- (void)addBtnAction{
    if (!WalletManager.isHavePassword) {
        [MBProgressHUD showSuccess:@"请先设置密码"];
        return;
    }
    
    [self routerEventForName:kYXWalletShowAddViewFountion paramater:nil];
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
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.addBtn];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(80);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.addBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(22);
        make.width.mas_equalTo(22);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
}

@end
