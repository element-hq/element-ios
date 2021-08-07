//
//  YXWalletCodeAssetsSelectCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCodeAssetsSelectCell.h"
#import "YXWalletCashModel.h"
@interface YXWalletCodeAssetsSelectCell ()
@property (nonatomic , strong) UIView *bgView;
@property (nonatomic , strong) UIImageView *headImageView;
@property (nonatomic , strong) UIImageView *rightIcon;
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UILabel *desLabel;

@end
@implementation YXWalletCodeAssetsSelectCell


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
    
    [self.contentView addSubview:self.bgView];
    
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.rightIcon];
    [self.bgView addSubview:self.headImageView];
    
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
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

}

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:YXWalletCashModel.class]) {
        self.bgView.layer.cornerRadius = 0;
        [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.top.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
        }];
    }else if ([rowData isKindOfClass:YXWalletMyWalletRecordsItem.class]) {
        YXWalletMyWalletRecordsItem *model = (YXWalletMyWalletRecordsItem *)rowData;
        _titleLabel.text = model.coinName;
        NSString *url = kImageURL(GET_A_NOT_NIL_STRING(model.image));
        YXWeakSelf
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url] options:(SDWebImageDownloaderAllowInvalidSSLCertificates|SDWebImageDownloaderUseNSURLCache) progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if (image && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.headImageView.image = image;
                });
            }
        }];
    }
}



@end
