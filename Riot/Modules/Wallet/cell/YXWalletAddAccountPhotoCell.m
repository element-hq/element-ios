//
//  YXWalletAddAccountPhotoCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountPhotoCell.h"
extern NSString *const kYXWalletAddAccountSelectPhoto;
@interface YXWalletAddAccountPhotoCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIImageView *addIcon;
@end

@implementation YXWalletAddAccountPhotoCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"微信收款码";
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
        _desLabel.text = @"请上传微信收款二维码";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = UIColor170;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

- (UIImageView *)addIcon{
    if (!_addIcon){
        _addIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"add_QR"]];
        _addIcon.contentMode = UIViewContentModeScaleAspectFill;
        _addIcon.clipsToBounds = YES;
        YXWeakSelf
        [_addIcon addTapAction:^(UITapGestureRecognizer * _Nonnull sender) {
            [weakSelf routerEventForName:kYXWalletAddAccountSelectPhoto paramater:nil];
        }];
    
    }
    return _addIcon;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.desLabel];
    [self.contentView addSubview:self.addIcon];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(120);
        make.top.mas_equalTo(18);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(14);
        make.width.mas_equalTo(150);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
    }];
    
    
    [self.addIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-24);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.width.mas_equalTo(78);
        make.height.mas_equalTo(78);
    }];
}



@end
