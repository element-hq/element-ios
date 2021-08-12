//
//  YXWalletSendTextFieldTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendTextFieldTableViewCell.h"
#import "YXWalletSendModel.h"
extern NSString *const kEndEditFieldTextNotification;
@interface YXWalletSendTextFieldTableViewCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)YXWalletSendModel *rowData;
@end

@implementation YXWalletSendTextFieldTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
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

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"未设置";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = WalletColor;
        _desLabel.textAlignment = NSTextAlignmentRight;
    }
    return _desLabel;
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
    
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.lineView];
    [self.bgView addSubview:self.textField];

    
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
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titleLabel.mas_right).offset(10);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(30);
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
    if ([rowData.name isEqualToString:@"发送数量"]) {
        NSString *count = [NSString stringWithFormat:@"可用：%.4f",rowData.currentSelectModel.balance];
        self.desLabel.text = [NSString stringWithFormat:@"（可用：%@ %@）",count,rowData.currentSelectModel.baseSymbol];
    }else{
        self.desLabel.text = rowData.desc;
    }
   
    self.textField.placeholder = rowData.placedholder;
}


- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    if ([self.rowData.name isEqualToString:@"发送数量"]) {
        self.rowData.currentSelectModel.sendCount = textField.text;
    }else if ([self.rowData.name isEqualToString:@"备注信息"]) {
        self.rowData.currentSelectModel.sendInfo = textField.text;
    }
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}

@end
