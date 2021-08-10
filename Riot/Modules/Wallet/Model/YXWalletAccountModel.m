//
//  YXWalletAccountModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAccountModel.h"

@implementation YXWalletAddAccountModel
@end

@implementation YXWalletAccountOptionsModel
@end

@implementation YXWalletAccountModel
- (NSMutableArray <YXWalletAccountModel *>*)getCellArrayWithBindingType:(YXWalletAccountBindingType)type{
    NSMutableArray *array = [NSMutableArray array];
    self.bindingType = type;
    if (type == YXWalletAccountCardType) {
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTitleCell" cellHeight:57 cellType:YXWalletAccountCellTitleType desc:@"请绑定持卡人本人的储蓄卡" name:@"" placedholder:@"" showLine:NO]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"持卡人" placedholder:@"请输入持卡人真实姓名" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"储蓄卡" placedholder:@"请输入储蓄卡卡号" showLine:YES]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"开户行" placedholder:@"请输入开户支行信息" showLine:YES]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"支行信息" placedholder:@"请输入支行信息" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"手机号码" placedholder:@"请输入银行预留手机号" showLine:YES]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountVerificationCodeCell" cellHeight:50 cellType:YXWalletAccountCellVerificationCodeType desc:@"" name:@"验证码" placedholder:@"请输入验证码" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:60 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletCopyTableViewCell" cellHeight:40 cellType:YXWalletAccountCellButtomType desc:@"银行卡" name:@"确定" placedholder:@"" showLine:NO]];
       
    }else if (type == YXWalletAccountZFBType){
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTitleCell" cellHeight:57 cellType:YXWalletAccountCellTitleType desc:@"请绑定本人的支付宝账号" name:@"" placedholder:@"" showLine:NO]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"姓名" placedholder:@"请输入账号真实姓名" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"支付宝" placedholder:@"请输入支付宝账号" showLine:YES]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"确认账号" placedholder:@"请再次输入支付宝账号" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:60 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletCopyTableViewCell" cellHeight:40 cellType:YXWalletAccountCellButtomType desc:@"支付宝" name:@"确定" placedholder:@"" showLine:NO]];
        
    }else if (type == YXWalletAccountWeCharType){
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTitleCell" cellHeight:57 cellType:YXWalletAccountCellTitleType desc:@"添加收款账户-微信收款" name:@"" placedholder:@"" showLine:NO]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"姓名" placedholder:@"请输入账号真实姓名" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"微信昵称" placedholder:@"请输入微信昵称" showLine:YES]];
        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountTextFieldCell" cellHeight:50 cellType:YXWalletAccountCellTextFieldType desc:@"" name:@"微信账号" placedholder:@"请输入微信账号" showLine:NO]];
//        [array addObject:[self createModelWithCellName:@"YXWalletAddAccountPhotoCell" cellHeight:170 cellType:YXWalletAccountCellPhotoType desc:@"微信收款码" name:@"请上传微信收款二维码" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:60 cellType:YXWalletAccountCellLineType desc:@"" name:@"" placedholder:@"" showLine:NO]];
        
        [array addObject:[self createModelWithCellName:@"YXWalletCopyTableViewCell" cellHeight:40 cellType:YXWalletAccountCellButtomType desc:@"微信" name:@"确定" placedholder:@"" showLine:NO]];
        
    }
    
    return array;
    
}

- (YXWalletAccountModel *)createModelWithCellName:(NSString *)cellName
                                       cellHeight:(CGFloat)cellheight
                                         cellType:(YXWalletAccountCellType)type
                                             desc:(NSString *)desc
                                             name:(NSString *)name
                                     placedholder:(NSString *)placedholder showLine:(BOOL)showLine{
    YXWalletAccountModel *model = [[YXWalletAccountModel alloc]init];
    model.cellName = cellName;
    model.cellHeight = cellheight;
    model.cellType = type;
    model.desc = desc;
    model.name = name;
    model.placedholder = placedholder;
    model.showLine = showLine;
    return model;
}

@end
