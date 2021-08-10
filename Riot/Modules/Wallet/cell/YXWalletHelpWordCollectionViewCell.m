//
//  YXWalletHelpWordCollectionViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletHelpWordCollectionViewCell.h"

@interface YXWalletHelpWordCollectionViewCell ()
@property (nonatomic , strong) UILabel *titleLabel;
@end

@implementation YXWalletHelpWordCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {

    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mas_centerX);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.height.mas_equalTo(26);
        make.width.mas_equalTo((SCREEN_WIDTH - 48)/4);
    }];

}


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"tony";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.layer.borderWidth = 1;
        _titleLabel.layer.borderColor = [UIColor colorWithRed:255/255.0 green:160/255.0 blue:0/255.0 alpha:1.00].CGColor;
        _titleLabel.layer.cornerRadius = 13;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text = title;
}

@end
