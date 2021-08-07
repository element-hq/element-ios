//
//  YXWalletAddCollectionViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddCollectionViewCell.h"

@interface YXWalletAddCollectionViewCell ()

@property (nonatomic , strong) UIImageView *addImageView;
@property (nonatomic , strong) UILabel *titleLabel;

@end

@implementation YXWalletAddCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {

    [self.contentView addSubview:self.addImageView];
    [self.contentView addSubview:self.titleLabel];
    
    [self.addImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(30);
        make.centerX.mas_equalTo(self.mas_centerX).offset(-35);
        make.centerY.mas_equalTo(self.mas_centerY);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.addImageView.mas_right).offset(8);
        make.right.mas_equalTo(0);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.height.mas_equalTo(12);
    }];
    
}

- (UIImageView *)addImageView{
    if (!_addImageView) {
        _addImageView = [[UIImageView alloc]init];
        _addImageView.contentMode = UIViewContentModeScaleAspectFill;
        _addImageView.layer.cornerRadius = 15;
        _addImageView.clipsToBounds = YES;
        _addImageView.image = FullGray_PLACEDHOLDER_IMG;
    }
    return _addImageView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = UIColor102;
        _titleLabel.clipsToBounds = YES;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(void)setModel:(YXWalletCoinDataModel *)model{
    _model = model;
    _titleLabel.text = model.coinName;
    NSString *url = kImageURL(GET_A_NOT_NIL_STRING(model.image));;
    YXWeakSelf
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url] options:(SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderUseNSURLCache) progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.addImageView.image = image;
            });
        }
    }];
}

@end
