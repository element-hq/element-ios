//
//  YXWalletSendViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendViewModel.h"
#import "YXWalletTipCloaseTableViewCell.h"
#import "YXWalletAssetsSelectTableViewCell.h"
#import "YXWalletContactTableViewCell.h"
@interface YXWalletSendViewModel ()
@property (nonatomic , strong)YXWalletSendModel *sendModel;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *currentSelectModel;
@property (nonatomic , strong)YXWalletSendDataInfo *sendDataInfo;
@end

@implementation YXWalletSendViewModel

-(YXWalletSendModel *)sendModel{
    if (!_sendModel) {
        _sendModel = [[YXWalletSendModel alloc]init];
    }
    return _sendModel;
}


- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model{
    
    [self.sectionItems removeAllObjects];
    self.currentSelectModel = model;
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    NSMutableArray <YXWalletSendModel *>*editUIArray = [self.sendModel getSendData];
    
    [editUIArray enumerateObjectsUsingBlock:^(YXWalletSendModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.currentSelectModel = model;
        SCETRowItem *rowItem = [SCETRowItem rowItemWithRowData:obj cellClassString:obj.cellName];
        rowItem.cellHeight = obj.cellHeight;
        [rowItems addObject:rowItem];
    }];
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadData) {
        self.reloadData();
    }
    YXWeakSelf
    [self.delegate setBlockTableViewDidSelectRowAtIndexPath:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tableView:tableView didSelectRowAtIndexPath:indexPath];
    }];
    
}

//创建交易
- (void)nextSendOperation{
    YXWeakSelf
    
    NSString *walletId = self.currentSelectModel.walletId;
    NSString *acceptAddr = self.currentSelectModel.sendAddress;
    NSString *amount = self.currentSelectModel.sendCount;
    NSString *message = self.currentSelectModel.sendInfo;

    if (acceptAddr.length == 0) {
        [MBProgressHUD showSuccess:@"请输入地址"];
        return;
    }

    if (amount.length == 0) {
        [MBProgressHUD showSuccess:@"请输入发送量"];
        return;
    }
    
    [MBProgressHUD showMessage:@""];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(walletId) forKey:@"walletId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(acceptAddr) forKey:@"acceptAddr"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(amount) forKey:@"amount"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(message) forKey:@"message"];

    [NetWorkManager POST:kURL(@"/transaction/create") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        YXWalletSendDataModel *model = [YXWalletSendDataModel mj_objectWithKeyValues:responseObject];
        model.data.coinDate = model.localDateTime;
        model.data.walletId = weakSelf.currentSelectModel.walletId;
        if (model.status == 200) {
            weakSelf.sendDataInfo = model.data;
            if (weakSelf.nextBlock) {
                weakSelf.nextBlock(model.data);
            }
        }else{
            [MBProgressHUD showError:model.msg];
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
    }];
    

}

//展示密码输入框
- (void)walletSendConfirmPay{
    
    //创建成功，验证密码没密码提醒用户去创建密码
    if (![YXWalletPasswordManager sharedYXWalletPasswordManager].isHavePassword) {
        [MBProgressHUD showSuccess:@"未设置密码请求前往设置"];
        return;
    }
    
    if (self.showInputPasswordViewBlock) {
        self.showInputPasswordViewBlock();
    }
}

//确认支付
- (void)confirmPay{
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(self.sendDataInfo.walletId) forKey:@"walletId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(self.sendDataInfo.txId) forKey:@"txId"];

    [NetWorkManager POST:kURL(@"/transaction/confirm") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        YXWalletSendConfirmPayModel *model = [YXWalletSendConfirmPayModel mj_objectWithKeyValues:responseObject];
        if (model.status == 200) {
            if (weakSelf.confirmPaySuccessBlock) {
                weakSelf.confirmPaySuccessBlock();
            }
        }

    } failure:^(NSError * _Nonnull error) {
        if (weakSelf.confirmPayFailError) {
            weakSelf.confirmPayFailError();
        }
    }];
    
}

- (void)cancelPay{
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(self.sendDataInfo.walletId) forKey:@"walletId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(self.sendDataInfo.txId) forKey:@"txId"];

    [NetWorkManager POST:kURL(@"/transaction/giveup") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        YXWalletSendConfirmPayModel *model = [YXWalletSendConfirmPayModel mj_objectWithKeyValues:responseObject];
        if (model.status == 200) {
            if (weakSelf.cancelPayBlock) {
                weakSelf.cancelPayBlock();
            }
        }

    } failure:^(NSError * _Nonnull error) {
        if (weakSelf.cancelPayFailBlock) {
            weakSelf.cancelPayFailBlock();
        }
    }];
}

//联系方式数据
- (void)reloadContactData:(YXWalletMyWalletRecordsItem *)model{
    YXWeakSelf
    [MBProgressHUD showMessage:@""];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [paramDict setObject:model.coinId forKey:@"coinId"];
    [NetWorkManager GET:kURL(@"/firend") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletSendFirendModel *firendModel = [YXWalletSendFirendModel mj_objectWithKeyValues:responseObject];
            if (firendModel.status == 200) {
                [weakSelf updateUserFirendWith:firendModel.data];
            }
  
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
    }];
}

- (void)updateUserFirendWith:(NSArray <YXWalletSendFirendDataItem *> *)array{
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    [array enumerateObjectsUsingBlock:^(YXWalletSendFirendDataItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCETRowItem *rowItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXWalletContactTableViewCell class])];
        rowItem.cellHeight = 60;
        [rowItems addObject:rowItem];
    }];
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadContactDataBlock) {
        self.reloadContactDataBlock();
    }
    YXWeakSelf
    [self.delegate setBlockTableViewDidSelectRowAtIndexPath:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tableView:tableView didSelectRowAtIndexPath:indexPath];
    }];
    
    
}


- (void)reloadConfirmationData:(YXWalletSendDataInfo *)model{
    self.sendDataInfo = model;
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    NSMutableArray <YXWalletSendModel *>*editUIArray = [self.sendModel getConfirmationData:model];
    
    [editUIArray enumerateObjectsUsingBlock:^(YXWalletSendModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.sendDataInfo = model;
        SCETRowItem *rowItem = [SCETRowItem rowItemWithRowData:obj cellClassString:obj.cellName];
        rowItem.cellHeight = obj.cellHeight;
        [rowItems addObject:rowItem];
    }];
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadData) {
        self.reloadData();
    }
    YXWeakSelf
    [self.delegate setBlockTableViewDidSelectRowAtIndexPath:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tableView:tableView didSelectRowAtIndexPath:indexPath];
    }];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    if (!sectionItem) {
        return;
    }

    SCETRowItem *rowItem = [sectionItem.rowItems sc_safeObjectAtIndex:indexPath.row];
    if (!rowItem) {
        return;
    }
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletAssetsSelectTableViewCell.class)]) {
        if (self.showSelectAssetsViewBlock) {
            self.showSelectAssetsViewBlock();
        }
    }
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletContactTableViewCell.class)]) {
        YXWalletSendFirendDataItem *model = (YXWalletSendFirendDataItem *)rowItem.rowData;
        if (self.selectFirendBlock) {
            self.selectFirendBlock(model.walletAddr);
        }
    }
    
}
@end
