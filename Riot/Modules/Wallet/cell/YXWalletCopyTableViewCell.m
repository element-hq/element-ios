//
//  YXWalletCopyTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCopyTableViewCell.h"
#import "YXWalletSendModel.h"
#import "YXWalletCashModel.h"
NSString *const kEndEditFieldTextNotification = @"kEndEditFieldTextNotification";
extern NSString *const kYXWalleBindingAccount;
extern NSString *const kYXWalletAddAccountUnBinding;
extern NSString *const kYXWalletCopyHelpWord;
extern NSString *const kYXWalletConfirmToCash;
extern NSString *const kYXWalletSendConfirmPay;
@interface YXWalletCopyTableViewCell ()
@property (nonatomic , strong)UILabel *copyLabel;
@end

@implementation YXWalletCopyTableViewCell


-(UILabel *)copyLabel{
    if (!_copyLabel) {
        _copyLabel = [[UILabel alloc]init];
        _copyLabel.numberOfLines = 0;
        _copyLabel.text = @"复制私钥";
        _copyLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _copyLabel.backgroundColor = WalletColor;
        _copyLabel.textColor = kWhiteColor;
        _copyLabel.textAlignment = NSTextAlignmentCenter;
        [_copyLabel mm_addTapGestureWithTarget:self action:@selector(copyLabelAction)];
        _copyLabel.layer.cornerRadius = 20;
        _copyLabel.layer.masksToBounds = YES;
    }
    return _copyLabel;
}

- (void)copyLabelAction{
    
    if ([self.copyLabel.text isEqualToString:@"复制私钥"]) {
        
    }else if ([self.copyLabel.text isEqualToString:@"复制助记词"]){
        [self routerEventForName:kYXWalletCopyHelpWord paramater:nil];
    }else if ([self.copyLabel.text isEqualToString:@"解除绑定"]){
        [self routerEventForName:kYXWalletAddAccountUnBinding paramater:nil];
    }else if ([self.copyLabel.text isEqualToString:@"确认支付"] || [self.copyLabel.text isEqualToString:@"继续支付"]){
        [self routerEventForName:kYXWalletSendConfirmPay paramater:nil];
    }else if ([self.copyLabel.text isEqualToString:@"确认兑现"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditFieldTextNotification object:nil];
        [self routerEventForName:kYXWalletConfirmToCash paramater:nil];
    }else if ([self.copyLabel.text isEqualToString:@"确定"]){
        [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditFieldTextNotification object:nil];
        [self routerEventForName:kYXWalleBindingAccount paramater:nil];
    }
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{

    [self.contentView addSubview:self.copyLabel];

    [self.copyLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(38);
        make.right.mas_equalTo(-38);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
}

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:NSString.class]) {
        _copyLabel.text = (NSString *)rowData;
    }else if ([rowData isKindOfClass:YXWalletSendModel.class]){
        YXWalletSendModel *model = (YXWalletSendModel *)rowData;
        _copyLabel.text = model.title;
    }else if ([rowData isKindOfClass:YXWalletCashModel.class]){
        YXWalletCashModel *model = (YXWalletCashModel *)rowData;
        _copyLabel.text = model.name;
    }else if ([rowData isKindOfClass:YXWalletAccountModel.class]){
        YXWalletAccountModel *model = (YXWalletAccountModel *)rowData;
        _copyLabel.text = model.name;
    }
    
    
}

@end

