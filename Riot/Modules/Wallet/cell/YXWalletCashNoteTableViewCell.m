//
//  YXWalletCashNoteTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashNoteTableViewCell.h"
#import "YXWalletCashModel.h"
extern NSString *const kEndEditFieldTextNotification;
extern NSString *const kAllCrashNotification;
@interface YXWalletCashNoteTableViewCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *allLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)YXWalletCashModel *rowData;
@end

@implementation YXWalletCashNoteTableViewCell
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
        _titleLabel.text = @"VCL";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}


-(UILabel *)allLabel{
    if (!_allLabel) {
        _allLabel = [[UILabel alloc]init];
        _allLabel.numberOfLines = 0;
        _allLabel.text = @"全部";
        _allLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _allLabel.textColor = WalletColor;
        _allLabel.textAlignment = NSTextAlignmentCenter;
        YXWeakSelf
        [_allLabel addTapAction:^(UITapGestureRecognizer * _Nonnull sender) {
            [weakSelf allLabelAction];
        }];
    }
    return _allLabel;
}

- (void)allLabelAction{
    
    NSString *balance = @(self.rowData.walletModel.balance).stringValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAllCrashNotification object:balance];
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"可兑换数量600.54 VCL";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = UIColor102;
        _desLabel.textAlignment = NSTextAlignmentLeft;
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
        _textField.placeholder = @"输入备注信息（选填）";
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
    
    [self.contentView addSubview:self.desLabel];
    [self.contentView addSubview:self.allLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.textField];
    [self.contentView addSubview:self.lineView];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(14);
        make.top.mas_equalTo(15);
    }];
    
    
    [self.allLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.desLabel.mas_right).offset(10);
        make.height.mas_equalTo(15);
        make.centerY.mas_equalTo(self.desLabel.mas_centerY);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(30);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(-32);
        make.height.mas_equalTo(1);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-15);
        make.bottom.mas_equalTo(self.lineView.mas_top).offset(-14);
    }];

}

-(void)setupCellWithRowData:(YXWalletCashModel *)rowData{
    _rowData = rowData;
    
    _desLabel.text = [NSString stringWithFormat:@"可兑换数量%@  %@",[NSString stringWithFormat:@"≈￥%.4f",rowData.walletModel.balance],rowData.walletModel.coinName];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _rowData.walletModel.cashNoteInfo = textField.text;
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}

@end
