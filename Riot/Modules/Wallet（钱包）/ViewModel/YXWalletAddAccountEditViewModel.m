//
//  YXWalletAddAccountEditViewModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountEditViewModel.h"
#import "YXWalletAccountModel.h"
@interface YXWalletAddAccountEditViewModel ()
@property (nonatomic , strong) YXWalletAccountModel *accountModel;
@property (nonatomic , strong) NSArray *imageData;
@end

@implementation YXWalletAddAccountEditViewModel

- (void)reloadNewDataWith:(YXWalletAccountBindingType)type{
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    NSMutableArray <YXWalletAccountModel *>* editUIArray = [self.accountModel getCellArrayWithBindingType:type];
    
    [editUIArray enumerateObjectsUsingBlock:^(YXWalletAccountModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        SCETRowItem *accountItem = [SCETRowItem rowItemWithRowData:obj cellClassString:obj.cellName];
        accountItem.cellHeight = obj.cellHeight;
        [rowItems addObject:accountItem];
        
    }];
    
    
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadData) {
        self.reloadData();
    }
    
}

- (void)walletAddAccountSelectPhoto{
    if (self.callCameraBlock) {
        self.callCameraBlock();
    }
}

- (void)uploadCommunityImages:(NSArray *)data{
    self.imageData = data;
    
    UIImage *image = [UIImage imageWithData:self.imageData.firstObject];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:@"1404735292388151298" forKey:@"conId"];
    
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    formatter.dateFormat=@"yyyyMMddHHmmss";
    NSString *str=[formatter stringFromDate:[NSDate date]];
    NSString *fileName=[NSString stringWithFormat:@"%@.png",str];
    

    [NetWorkManager UpLoadWithPOST:kURL(@"/config/upload") parameters:paramDict image:image imageName:@"file" fileName:fileName progress:^(NSProgress * _Nullable progress) {
        
    } success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
   
        }
    } failure:^(NSError * _Nonnull error) {
        
    }];
    
    
}




- (void)walleBindingAccount{
    
    
    __block NSString *nick = @"";
    __block NSString *userName = @"";
    __block NSString *account = @"";
    __block NSString *zfbAccount = @"";
    __block NSString *bank = @"";
    __block NSString *phone = @"";
    __block NSString *vfCode = @"";
    __block NSString *subbranch = @"";
    
    //获取请求参数
    [self.sectionItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCETSectionItem *sectionItem = obj;
        [sectionItem.rowItems enumerateObjectsUsingBlock:^(SCETRowItem * _Nonnull rowItem, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([rowItem.cellClassString isEqualToString:@"YXWalletAddAccountTextFieldCell"]) {
                YXWalletAccountModel *model = (YXWalletAccountModel *)rowItem.rowData;
                
                if ([model.name isEqualToString:@"姓名"] || [model.name isEqualToString:@"持卡人"]) {
                    userName = model.userName;
                    nick = model.userName;
                }else if ([model.name isEqualToString:@"开户行"]) {
                    bank = model.bank;
                }else if ([model.name isEqualToString:@"储蓄卡"]) {
                    account = model.account;
                }else if ([model.name isEqualToString:@"支行信息"]) {
                    subbranch = model.subbranch;
                }else if ([model.name isEqualToString:@"手机号码"]) {
                    phone = model.phone;
                }else if ([model.name isEqualToString:@"支付宝"]) {
                    zfbAccount = model.zfbAccount;
                }else if ([model.name isEqualToString:@"确认账号"]) {
                    account = model.account;
                }else if ([model.name isEqualToString:@"微信昵称"]) {
                    nick = model.nick;
                }else if ([model.name isEqualToString:@"微信账号"]) {
                    account = model.account;
                }
                
                
                
            }else if ([rowItem.cellClassString isEqualToString:@"YXWalletAddAccountVerificationCodeCell"]) {
                YXWalletAccountModel *model = (YXWalletAccountModel *)rowItem.rowData;
                
                if ([model.name isEqualToString:@"验证码"]) {
                    vfCode = model.vfCode;
                }
            }
        }];
    }];
    
    if (self.accountModel.bindingType == YXWalletAccountCardType) {
        
        if (userName.length == 0) {
            [MBProgressHUD showSuccess:@"请输入账号真实姓名"];
            return;
        }
        if (account.length == 0) {
            [MBProgressHUD showSuccess:@"请输入储蓄卡号"];
            return;
        }
        if (bank.length == 0) {
            [MBProgressHUD showSuccess:@"请输入开户行"];
            return;
        }
        if (phone.length == 0) {
            [MBProgressHUD showSuccess:@"请输入手机号码"];
            return;
        }
        if (vfCode.length == 0) {
            [MBProgressHUD showSuccess:@"请输入验证码"];
            return;
        }
        
        [MBProgressHUD showMessage:@"添加中..."];
        
        YXWalletAccountOptionsModel *optionsModel = [[YXWalletAccountOptionsModel alloc]init];
        optionsModel.userName = userName;
        optionsModel.account = account;
        optionsModel.subbranch = subbranch;
        optionsModel.bank = bank;
        optionsModel.phone = phone;
        optionsModel.vfCode = vfCode;
        
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
        [paramDict setObject:optionsModel.mj_keyValues forKey:@"options"];
        [paramDict setObject:@(1) forKey:@"type"];
        [paramDict setObject:WalletManager.userId forKey:@"userId"];
        
        
        NSError *error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramDict options:0 error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [NetWorkManager POST:kURL(@"/account") parameters:jsonString headers:[NSMutableDictionary dictionary] success:^(id  _Nonnull responseObject) {
            [MBProgressHUD hideHUD];
            if ([responseObject isKindOfClass:NSDictionary.class]) {
                NSDictionary *dic = responseObject;
                YXWalletAddAccountModel *model = [YXWalletAddAccountModel mj_objectWithKeyValues:dic];
                if (model.status == 200) {
                    if (self.addSuccessBlock) {
                        self.addSuccessBlock();
                    }
                }else{
                    [MBProgressHUD showError:@"添加失败"];
                }
            }
            
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUD];
            [MBProgressHUD showError:@"添加失败"];
        }];
        
    }else if (self.accountModel.bindingType == YXWalletAccountZFBType) {
        
        
        if (userName.length == 0) {
            [MBProgressHUD showSuccess:@"请输入账号真实姓名"];
            return;
        }
        if (zfbAccount.length == 0) {
            [MBProgressHUD showSuccess:@"请输入支付宝账号"];
            return;
        }
        
        if (account.length == 0) {
            [MBProgressHUD showSuccess:@"请确认支付宝账号"];
            return;
        }
        
        if (![account isEqualToString:zfbAccount]) {
            [MBProgressHUD showSuccess:@"输入账号不一致"];
            return;
        }
        
        [MBProgressHUD showMessage:@"添加中..."];
        
        YXWalletAccountOptionsModel *optionsModel = [[YXWalletAccountOptionsModel alloc]init];
        optionsModel.userName = userName;
        optionsModel.account = account;
        
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
        [paramDict setObject:optionsModel.mj_keyValues forKey:@"options"];
        [paramDict setObject:@(3) forKey:@"type"];
        [paramDict setObject:WalletManager.userId forKey:@"userId"];
        
        
        NSError *error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramDict options:0 error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [NetWorkManager POST:kURL(@"/account") parameters:jsonString headers:[NSMutableDictionary dictionary] success:^(id  _Nonnull responseObject) {
            [MBProgressHUD hideHUD];
            if ([responseObject isKindOfClass:NSDictionary.class]) {
                NSDictionary *dic = responseObject;
                YXWalletAddAccountModel *model = [YXWalletAddAccountModel mj_objectWithKeyValues:dic];
                if (model.status == 200) {
                    if (self.addSuccessBlock) {
                        self.addSuccessBlock();
                    }
                }else{
                    [MBProgressHUD showError:@"添加失败"];
                }
            }
            
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUD];
            [MBProgressHUD showError:@"添加失败"];
        }];
        
    }else if (self.accountModel.bindingType == YXWalletAccountWeCharType) {
        
        if (userName.length == 0) {
            [MBProgressHUD showSuccess:@"请输入账号真实姓名"];
            return;
        }
        if (nick.length == 0) {
            [MBProgressHUD showSuccess:@"请输入昵称"];
            return;
        }
        
        if (account.length == 0) {
            [MBProgressHUD showSuccess:@"请确认微信账号"];
            return;
        }
        
        [MBProgressHUD showMessage:@"添加中..."];
        
        
        YXWalletAccountOptionsModel *optionsModel = [[YXWalletAccountOptionsModel alloc]init];
        optionsModel.userName = userName;
        optionsModel.nick = nick;
        optionsModel.account = account;
        
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
        [paramDict setObject:optionsModel.mj_keyValues forKey:@"options"];
        [paramDict setObject:@(2) forKey:@"type"];
        [paramDict setObject:WalletManager.userId forKey:@"userId"];
        
        
        NSError *error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramDict options:0 error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [NetWorkManager POST:kURL(@"/account") parameters:jsonString headers:[NSMutableDictionary dictionary] success:^(id  _Nonnull responseObject) {
            [MBProgressHUD hideHUD];
            if ([responseObject isKindOfClass:NSDictionary.class]) {
                NSDictionary *dic = responseObject;
                YXWalletAddAccountModel *model = [YXWalletAddAccountModel mj_objectWithKeyValues:dic];
                if (model.status == 200) {
                    if (self.addSuccessBlock) {
                        self.addSuccessBlock();
                    }
                }else{
                    [MBProgressHUD showError:@"添加失败"];
                }
            }
            
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUD];
            [MBProgressHUD showError:@"添加失败"];
        }];
        
    }
    
}



-(YXWalletAccountModel *)accountModel{
    if (!_accountModel) {
        _accountModel = [[YXWalletAccountModel alloc]init];
    }
    return _accountModel;
}


@end
