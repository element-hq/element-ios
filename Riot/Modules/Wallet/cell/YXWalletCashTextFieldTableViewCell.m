//
//  YXWalletCashTextFieldTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashTextFieldTableViewCell.h"
#import "YXWalletCashModel.h"
extern NSString *const kEndEditFieldTextNotification;
@interface YXWalletCashTextFieldTableViewCell ()<UITextFieldDelegate>
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)YXWalletCashModel *rowData;
@end

@implementation YXWalletCashTextFieldTableViewCell
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
        _titleLabel.textAlignment = NSTextAlignmentRight;
    }
    return _titleLabel;
}


-(UITextField *)textField{
    if (!_textField) {
        _textField = [[UITextField alloc]init];
        _textField.textAlignment = NSTextAlignmentLeft;
        _textField.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _textField.textColor = UIColor51;
        _textField.delegate = self;
        _textField.placeholder = @"输入兑换数量";
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
        make.right.mas_equalTo(-15);
        make.height.mas_equalTo(20);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-130);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];

}

-(void)setupCellWithRowData:(YXWalletCashModel *)rowData{
    _rowData = rowData;
    self.titleLabel.text = rowData.walletModel.coinName;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    _rowData.walletModel.cashCount = textField.text;
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)endEditFieldTextNotification{
    [self.textField resignFirstResponder];
}


@end
