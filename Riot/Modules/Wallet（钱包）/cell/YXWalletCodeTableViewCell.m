//
//  YXWalletCodeTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCodeTableViewCell.h"
extern NSString *const kYXWalletRefreshAddress;
@interface YXWalletCodeTableViewCell ()
@property (nonatomic , strong) UIView *lineView;
@property (nonatomic , strong) UIView *bgView;
@property (nonatomic , strong) UIImageView *codeImageView;
@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UILabel *desLabel;
@property (nonatomic , strong) UILabel *copysLabel;
@property (nonatomic , strong) UILabel *refreshLabel;
@property (nonatomic , strong) YXWalletMyWalletRecordsItem *rowData;
@end
@implementation YXWalletCodeTableViewCell


-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}


- (UIImageView *)codeImageView{
    if (!_codeImageView) {
        _codeImageView = [[UIImageView alloc]init];
        _codeImageView.contentMode = UIViewContentModeScaleAspectFill;
        _codeImageView.layer.cornerRadius = 10;
        _codeImageView.clipsToBounds = YES;
        _codeImageView.image = FullGray_PLACEDHOLDER_IMG;
    }
    return _codeImageView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"VCL:SWqtFi7CE9WM6pafRdS8ExiQjPt4aDvoRu";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor51;
        _desLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _desLabel;
}

-(UILabel *)copysLabel{
    if (!_copysLabel) {
        _copysLabel = [[UILabel alloc]init];
        _copysLabel.numberOfLines = 0;
        _copysLabel.text = @"复制地址";
        _copysLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _copysLabel.textColor = WalletColor;
        _copysLabel.textAlignment = NSTextAlignmentCenter;
        YXWeakSelf
        [_copysLabel addTapAction:^(UITapGestureRecognizer *sender) {
            UIPasteboard *pab = [UIPasteboard generalPasteboard];
            [pab setString:GET_A_NOT_NIL_STRING(weakSelf.rowData.address)];
            [MBProgressHUD showSuccess:@"复制成功"];
        }];
    }
    return _copysLabel;
}

-(UILabel *)refreshLabel{
    if (!_refreshLabel) {
        _refreshLabel = [[UILabel alloc]init];
        _refreshLabel.numberOfLines = 0;
        _refreshLabel.text = @"刷新地址";
        _refreshLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _refreshLabel.textColor = WalletColor;
        _refreshLabel.textAlignment = NSTextAlignmentCenter;
        YXWeakSelf
        [_refreshLabel addTapAction:^(UITapGestureRecognizer *sender) {
            [weakSelf routerEventForName:kYXWalletRefreshAddress paramater:nil];
        }];
    }
    return _refreshLabel;
}



-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"扫描二维码，向我支付VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = RGB(204, 204, 204);
    }
    return _lineView;
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
    [self.bgView addSubview:self.codeImageView];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.lineView];
    [self.bgView addSubview:self.copysLabel];
    [self.bgView addSubview:self.refreshLabel];

    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(45);
        make.height.mas_equalTo(20);
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
    }];
    
    [self.codeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(30);
        make.height.mas_equalTo(200);
        make.width.mas_equalTo(200);
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.codeImageView.mas_bottom).offset(30);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
    }];


    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(1);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(15);
    }];

    [self.copysLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.lineView.mas_centerY);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(52);
        make.right.mas_equalTo(self.lineView.mas_left).offset(-15);
    }];
    
    [self.refreshLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.lineView.mas_centerY);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(52);
        make.left.mas_equalTo(self.lineView.mas_right).offset(15);
    }];

}

-(void)setupCellWithRowData:(YXWalletMyWalletRecordsItem *)rowData{
    _rowData = rowData;
    UIImage *image = [self createQRCodeWithUrl:rowData.address];
    self.codeImageView.image = image;
    self.titleLabel.text = [NSString stringWithFormat:@"扫描二维码，向我支付%@",rowData.baseSymbol];
    self.desLabel.text = [NSString stringWithFormat:@"%@:%@",rowData.baseSymbol,rowData.address];
}


- (UIImage *)createQRCodeWithUrl:(NSString *)url {
    // 1. 创建一个二维码滤镜实例(CIFilter)
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];

    // 2. 给滤镜添加数据
    NSString *string = url;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    // 使用KVC的方式给filter赋值
    [filter setValue:data forKeyPath:@"inputMessage"];

    // 3. 生成二维码
    CIImage *image = [filter outputImage];
    // 转成高清格式
    UIImage *qrcode = [self createNonInterpolatedUIImageFormCIImage:image withSize:200];

    return qrcode;
}


// 将二维码转成高清的格式
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {

    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));

    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
@end
