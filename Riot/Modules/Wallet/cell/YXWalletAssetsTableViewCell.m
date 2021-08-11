//
//  YXWalletAssetsTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAssetsTableViewCell.h"
#import "YXWalletMyWalletModel.h"
@interface YXWalletAssetsTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIImageView *titleIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *countLabel;
@property (nonatomic , strong)UILabel *numLabel;
@end

@implementation YXWalletAssetsTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        UIView *view = [[UIView alloc] init];
        view.alpha = 1;
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = 10;
        _bgView = view;
    }
    return _bgView;
}

- (UIImageView *)titleIcon{
    if (!_titleIcon){
        _titleIcon = [[UIImageView alloc]initWithImage:FullGray_PLACEDHOLDER_IMG];
        _titleIcon.contentMode = UIViewContentModeScaleAspectFill;
        _titleIcon.layer.masksToBounds = YES;
        _titleIcon.layer.cornerRadius = 20;
    }
    return _titleIcon;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = RGB(102, 102, 102);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"￥1.237";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = RGB(170, 170, 170);
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)countLabel{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc]init];
        _countLabel.numberOfLines = 0;
        _countLabel.text = @"94562157.67";
        _countLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _countLabel.textColor = RGB(102, 102, 102);
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    return _countLabel;
}

-(UILabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [[UILabel alloc]init];
        _numLabel.numberOfLines = 0;
        _numLabel.text = @"≈￥116973389.04";
        _numLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _numLabel.textColor = RGB(170, 170, 170);
        _numLabel.textAlignment = NSTextAlignmentRight;
    }
    return _numLabel;
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
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.titleIcon];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.countLabel];
    [self.bgView addSubview:self.numLabel];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(0);
        make.left.mas_equalTo(16);
        make.right.mas_equalTo(-16);
    }];
    
    [self.titleIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(10);
        make.width.height.mas_equalTo(40);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(12);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(18);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-12);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(14);
    }];
    
    [self.countLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(12);
        make.left.mas_equalTo(self.titleLabel.mas_right).offset(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(18);
    }];
    
    [self.numLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-12);
        make.left.mas_equalTo(self.desLabel.mas_right).offset(10);
        make.right.mas_equalTo(-10);
        make.height.mas_equalTo(14);
    }];
    
}

-(void)setupCellWithRowData:(YXWalletMyWalletRecordsItem *)rowData{
    _titleLabel.text = rowData.coinName;
    _desLabel.text = [NSString stringWithFormat:@"￥%@",rowData.fundValue];
    _countLabel.text = @(rowData.balance).stringValue;//余额
    _numLabel.text = [NSString stringWithFormat:@"≈￥%.4f",rowData.fundValue.floatValue * rowData.balance];
    
    NSString *url = kImageURL(GET_A_NOT_NIL_STRING(rowData.image));
    YXWeakSelf
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url] options:(SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderUseNSURLCache) progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.titleIcon.image = image;
            });
        }
    }];
}

@end
