//
//  YXWalletAddAccountTitleCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountTitleCell.h"

@interface YXWalletAddAccountTitleCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@end

@implementation YXWalletAddAccountTitleCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"请绑定持卡人本人的储蓄卡";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = UIColor153;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
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
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(-15);
        make.height.mas_equalTo(15);
    }];
    
}

-(void)setupCellWithRowData:(id)rowData{
    
    if ([rowData isKindOfClass:YXWalletAccountModel.class]) {
        YXWalletAccountModel *model = (YXWalletAccountModel *)rowData;
        self.titleLabel.text = model.desc;
    }
    
    
}

@end
