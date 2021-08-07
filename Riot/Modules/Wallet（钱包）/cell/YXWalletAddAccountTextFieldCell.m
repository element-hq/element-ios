//
//  YXWalletAddAccountTextFieldCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountTextFieldCell.h"
extern NSString *const kEndEditFieldTextNotification;
@interface YXWalletAddAccountTextFieldCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)YXWalletAccountModel *rowData;

@end

@implementation YXWalletAddAccountTextFieldCell

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
    [self.contentView addSubview:self.lineView];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(16);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(90);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-16);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
   
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
}

-(void)setupCellWithRowData:(YXWalletAccountModel *)rowData
{
    self.rowData = rowData;
    self.textField.placeholder = rowData.placedholder;
    self.titleLabel.text = rowData.name;
    self.lineView.hidden = !rowData.showLine;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    if ([self.rowData.name isEqualToString:@"姓名"] || [self.rowData.name isEqualToString:@"持卡人"]) {
        self.rowData.userName = textField.text;
    }else if ([self.rowData.name isEqualToString:@"开户行"]) {
        self.rowData.bank = textField.text;
    }else if ([self.rowData.name isEqualToString:@"储蓄卡"]) {
        self.rowData.account = textField.text;
    }else if ([self.rowData.name isEqualToString:@"手机号码"]) {
        self.rowData.phone = textField.text;
    }else if ([self.rowData.name isEqualToString:@"支行信息"]) {
        self.rowData.subbranch = textField.text;
    }else if ([self.rowData.name isEqualToString:@"支付宝"]) {
        self.rowData.zfbAccount = textField.text;
    }else if ([self.rowData.name isEqualToString:@"确认账号"]) {
        self.rowData.account = textField.text;
    }else if ([self.rowData.name isEqualToString:@"微信昵称"]) {
        self.rowData.nick = textField.text;
    }else if ([self.rowData.name isEqualToString:@"微信账号"]) {
        self.rowData.account = textField.text;
    }
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}

@end
