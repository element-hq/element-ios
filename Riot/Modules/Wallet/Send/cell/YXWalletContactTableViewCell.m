//
//  YXWalletContactTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletContactTableViewCell.h"
#import "YXWalletSendModel.h"
@interface YXWalletContactTableViewCell ()
@property (nonatomic , strong) UIImageView *headImageView;
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong)UIView *lineView;
@end

@implementation YXWalletContactTableViewCell

- (UIImageView *)headImageView{
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc]init];
        _headImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headImageView.layer.cornerRadius = 20;
        _headImageView.clipsToBounds = YES;
        _headImageView.image = FullGray_PLACEDHOLDER_IMG;
    }
    return _headImageView;
}



-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = kWhiteColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.headImageView];
    [self.contentView addSubview:self.lineView];
    
    [self.headImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(40);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headImageView.mas_right).offset(15);
        make.height.mas_equalTo(20);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titleLabel.mas_left);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
   
}

-(void)setupCellWithRowData:(YXWalletSendFirendDataItem *)rowData{
    self.titleLabel.text = rowData.nickName;
    YXWeakSelf
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:rowData.url] options:(SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderUseNSURLCache) progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.headImageView.image = image;
            });
        }
    }];
}

@end
