//
//  YXWalletSendAddressTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendAddressTableViewCell.h"
#import "YXWalletSendModel.h"
extern NSString *const kYXWalletJumpContactView;
extern NSString *const kYXWalletJumpScanView;
extern NSString *const kEndEditFieldTextNotification;
@interface YXWalletSendAddressTableViewCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *bottombgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UIImageView *scanImage;
@property (nonatomic , strong)UIImageView *addressImage;
@property (nonatomic , strong)YXWalletSendModel *rowData;
@end

@implementation YXWalletSendAddressTableViewCell

- (UIImageView *)scanImage{
    if (!_scanImage){
        _scanImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"scan_icon"]];
        _scanImage.contentMode = UIViewContentModeScaleAspectFill;
        YXWeakSelf
        [_scanImage addTapAction:^(UITapGestureRecognizer *sender) {
            [weakSelf routerEventForName:kYXWalletJumpScanView paramater:nil];
        }];
    }
    return _scanImage;
}

- (UIImageView *)addressImage{
    if (!_addressImage){
        _addressImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"tonx_icon"]];
        _addressImage.contentMode = UIViewContentModeScaleAspectFill;
        YXWeakSelf
        [_addressImage addTapAction:^(UITapGestureRecognizer *sender) {
            [weakSelf routerEventForName:kYXWalletJumpContactView paramater:nil];
        }];
    }
    return _addressImage;
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

-(UIView *)bottombgView{
    if (!_bottombgView) {
        _bottombgView = [[UIView alloc]init];
        _bottombgView.backgroundColor = kWhiteColor;
    }
    return _bottombgView;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"收款账户";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = RGB(102, 102, 102);
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}


-(UITextField *)textField{
    if (!_textField) {
        _textField = [[UITextField alloc]init];
        _textField.textAlignment = NSTextAlignmentLeft;
        _textField.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _textField.textColor = UIColor51;
        _textField.delegate = self;
        _textField.placeholder = @"请输入持卡人真实姓名";
    }
    return _textField;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = kBgColor;
        [self setupUI];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditFieldTextNotification) name:kEndEditFieldTextNotification object:nil];
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.bottombgView];
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.scanImage];
    [self.bgView addSubview:self.addressImage];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.lineView];
    [self.bgView addSubview:self.textField];

    [self.bottombgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    

    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(30);
        make.width.mas_equalTo(65);
    }];
    
    [self.scanImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-15);
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
    }];
    

    [self.addressImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(self.scanImage.mas_left).offset(-20);
        make.centerY.mas_equalTo(self.titleLabel.mas_centerY);
    }];
    
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-16);
        make.bottom.mas_equalTo(self.lineView.mas_top).offset(-10);
    }];

    
}

-(void)setupCellWithRowData:(YXWalletSendModel *)rowData{
    self.rowData = rowData;
    self.titleLabel.text = rowData.name;
    self.textField.placeholder = rowData.placedholder;
    if (rowData.currentSelectModel.sendAddress.length > 0) {
        self.textField.text = rowData.currentSelectModel.sendAddress;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if ([self.rowData.name isEqualToString:@"钱包地址"]) {
        self.rowData.currentSelectModel.sendAddress = textField.text;
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}

@end
