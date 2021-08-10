//
//  YXWalletAddAccountVerificationCodeCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountVerificationCodeCell.h"
extern NSString *const kEndEditFieldTextNotification;
@interface YXWalletAddAccountVerificationCodeCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UILabel *verificationCode;
@property (nonatomic , strong)YXWalletAccountModel *rowData;

@end
@implementation YXWalletAddAccountVerificationCodeCell


-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"收款账户";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
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

-(UILabel *)verificationCode{
    if (!_verificationCode) {
        _verificationCode = [[UILabel alloc]init];
        _verificationCode.numberOfLines = 0;
        _verificationCode.text = @"验证码";
        _verificationCode.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _verificationCode.backgroundColor = WalletColor;
        _verificationCode.textColor = kWhiteColor;
        _verificationCode.textAlignment = NSTextAlignmentCenter;
        [_verificationCode mm_addTapGestureWithTarget:self action:@selector(verificationCodeAction)];
        _verificationCode.layer.cornerRadius = 15;
        _verificationCode.layer.masksToBounds = YES;
    }
    return _verificationCode;
}

- (void)verificationCodeAction{
    
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditFieldTextNotification) name:kEndEditFieldTextNotification object:nil];
        
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.textField];
    [self.contentView addSubview:self.verificationCode];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(90);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-120);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.verificationCode mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
        make.right.mas_equalTo(-16);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
   
    
}

-(void)setupCellWithRowData:(YXWalletAccountModel *)rowData
{
    self.rowData = rowData;
    self.textField.placeholder = rowData.placedholder;
    self.titleLabel.text = rowData.name;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if ([self.rowData.name isEqualToString:@"验证码"]) {
        self.rowData.vfCode = textField.text;
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}

@end
