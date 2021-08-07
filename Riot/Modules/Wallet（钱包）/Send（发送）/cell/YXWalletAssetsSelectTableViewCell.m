//
//  YXWalletAssetsSelectTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAssetsSelectTableViewCell.h"
#import "YXWalletSendModel.h"
@interface YXWalletAssetsSelectTableViewCell ()
@property (nonatomic , strong) UIView *shadowView;
@property (nonatomic , strong) UIView *bgView;
@property (nonatomic , strong) UIImageView *headImageView;
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UILabel *desLabel;
@property (nonatomic , strong) UILabel *tipLabel;
@property (nonatomic , strong) UIImageView *rightIcon;
@end
@implementation YXWalletAssetsSelectTableViewCell

-(UIView *)shadowView{
    if (!_shadowView) {
        _shadowView = [[UIView alloc]init];
        _shadowView.layer.cornerRadius = 10;
        _shadowView.clipsToBounds = YES;
        _shadowView.backgroundColor = RGBA(238, 238, 238, 1);
    }
    return _shadowView;
}


-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

- (UIImageView *)rightIcon{
    if (!_rightIcon){
        _rightIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"setting_next"]];
        _rightIcon.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _rightIcon;
}

- (UIImageView *)headImageView{
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc]init];
        _headImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headImageView.layer.cornerRadius = 10;
        _headImageView.clipsToBounds = YES;
        _headImageView.image = FullGray_PLACEDHOLDER_IMG;
    }
    return _headImageView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"资产种类";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _desLabel.textColor = UIColor51;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.text = @"VCL总余额：2000.00 VCL";
        _tipLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _tipLabel.textColor = WalletColor;
        _tipLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _tipLabel;
}


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor102;
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
    
    [self.contentView addSubview:self.shadowView];
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.tipLabel];
    
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.rightIcon];
    [self.bgView addSubview:self.headImageView];
    
    [self.shadowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(60);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(16);
        make.width.mas_equalTo(120);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.rightIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(8);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.rightIcon.mas_left).offset(-10);
        make.height.mas_equalTo(20);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    

    [self.headImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.titleLabel.mas_left).offset(-10);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(20);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(30);
        make.right.mas_equalTo(-15);
        make.bottom.mas_equalTo(-10);
        make.height.mas_equalTo(12);
    }];
    
}

-(void)setupCellWithRowData:(YXWalletSendModel *)rowData{
    
    _titleLabel.text = rowData.currentSelectModel.coinName;
    _tipLabel.text = [NSString stringWithFormat:@"%@总余额：%@ VCL",rowData.currentSelectModel.coinName,[NSString stringWithFormat:@"≈￥%@",@(rowData.currentSelectModel.fundValue.floatValue * rowData.currentSelectModel.balance).stringValue]];
    
    NSString *url = kImageURL(GET_A_NOT_NIL_STRING(rowData.currentSelectModel.image));
    YXWeakSelf
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url] options:(SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderUseNSURLCache) progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.headImageView.image = image;
            });
        }
    }];
    
}


@end
