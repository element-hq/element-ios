//
//  YXWalletCashViewModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashViewModel.h"
#import "YXWalletCodeAssetsSelectCell.h"
#import "YXWalletCodeTableViewCell.h"
#import "YXWalletCashModel.h"
#import "YXWalletCashRecordTableViewCell.h"
#import "YXWalletPaymentAccountViewModel.h"
#import "YXWalletPasswordManager.h"
#import "YXWalletRecordNoDataTableViewCell.h"
@interface YXWalletCashViewModel ()
@property (nonatomic , strong) YXWalletPaymentAccountViewModel *accountViewModel;
@property (nonatomic , strong) YXWalletCashModel *cashViewModel;
@property (nonatomic , assign) NSInteger currentPage;
@property (nonatomic , strong) YXWalletMyWalletRecordsItem *walletModel;
@property (nonatomic , strong) YXWalletCashCreateModel *cashCreateModel;
@end

@implementation YXWalletCashViewModel

-(YXWalletPaymentAccountViewModel *)accountViewModel{
    if (!_accountViewModel) {
        _accountViewModel = [[YXWalletPaymentAccountViewModel alloc]init];
        YXWeakSelf
        [_accountViewModel setGetDefaultAccountBlock:^(YXWalletPaymentAccountRecordsItem * _Nonnull model) {
            [weakSelf reloadNewData:model];
        }];
        
        [_accountViewModel setSettingAccountNotiBlock:^{
            [MBProgressHUD showSuccess:@"请添加收款账户"];
            if (weakSelf.showAddCardBlock) {
                weakSelf.showAddCardBlock();
            }
        }];
    }
    return _accountViewModel;
}

//获取默认账户数据
- (void)getCurrentAcountData:(YXWalletMyWalletRecordsItem *)model{
    self.walletModel = model;
    [self.accountViewModel reloadNewData];
}

- (void)reloadNewData:(YXWalletPaymentAccountRecordsItem *)model{
    
    self.walletModel.accountId = model.ID;
    
    [self.sectionItems removeAllObjects];
    YXWeakSelf
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];

    NSMutableArray <YXWalletCashModel *>*editUIArray = [self.cashViewModel getCellArray];
    
    [editUIArray enumerateObjectsUsingBlock:^(YXWalletCashModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.accountModel = model;
        obj.walletModel = weakSelf.walletModel;
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

    
    [self.delegate setBlockTableViewDidSelectRowAtIndexPath:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tableView:tableView didSelectRowAtIndexPath:indexPath];

    }];
    
}

- (void)reloadAddCardData{
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    NSMutableArray <YXWalletCashModel *>*editUIArray = [self.cashViewModel getAddCardCellArray];
    
    [editUIArray enumerateObjectsUsingBlock:^(YXWalletCashModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletCodeAssetsSelectCell.class)]) {
        if (self.showSelectAssetsViewBlock) {
            self.showSelectAssetsViewBlock();
        }
    }else if ([rowItem.cellClassString isEqualToString:@"YXWalletCashCardTableViewCell"]){
        if (self.showAddCardBlock) {
            self.showAddCardBlock();
        }
    }
}

-(YXWalletCashModel *)cashViewModel{
    if (!_cashViewModel) {
        _cashViewModel = [[YXWalletCashModel alloc]init];
    }
    return _cashViewModel;
}

- (void)reloadRecordData:(YXWalletMyWalletRecordsItem *)model{
    self.currentPage = 1;
    [self.sectionItems removeAllObjects];
    
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"walletId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/cash/record") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletCashExampleModelName *myWalletModel = [YXWalletCashExampleModelName mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf setupListHeadData:myWalletModel.data.records];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
        if (weakSelf.failDataBlock) {
            weakSelf.failDataBlock();
        }
    }];
}

- (void)reloadMoreRecordData:(YXWalletMyWalletRecordsItem *)model{
    self.currentPage += 1;
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"walletId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/cash/record") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletCashExampleModelName *myWalletModel = [YXWalletCashExampleModelName mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf setupListHeadData:myWalletModel.data.records];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
        if (weakSelf.failDataBlock) {
            weakSelf.failDataBlock();
        }
    }];
}

- (void)setupListHeadData:(NSArray *)array {
    
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    if (self.currentPage == 1) {
        SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:kBgColor cellClassString:NSStringFromClass([YXLineTableViewCell class])];
        lineItem.cellHeight = 30;
        [rowItems addObject:lineItem];
        
        if (array.count == 0) {
            SCETRowItem *noData = [SCETRowItem rowItemWithRowData:kBgColor cellClassString:NSStringFromClass([YXWalletRecordNoDataTableViewCell class])];
            noData.cellHeight = 240;
            [rowItems addObject:noData];
        }
    }

    //资产列表
    [array enumerateObjectsUsingBlock:^(YXWalletCashRecordsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCETRowItem *assetsItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXWalletCashRecordTableViewCell class])];
        assetsItem.cellHeight =  obj.status == -1 ? 130 : 100;
        [rowItems addObject:assetsItem];
    }];
    
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    YXWeakSelf
    [self.delegate setBlockTableViewDidSelectRowAtIndexPath:^(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath) {
        [weakSelf tableView:tableView didSelectRowAtIndexPath:indexPath];
    }];
    
    if (self.reloadData) {
        self.reloadData();
    }
    
}

//确认兑现
- (void)walletConfirmToCash{
    
    YXWeakSelf
    
    NSString *walletId = self.walletModel.walletId;
    NSString *accoutId = self.walletModel.accountId;
    NSString *amount = self.walletModel.cashCount;
    NSString *cashFees = self.walletModel.cashFee;
    NSString *message = self.walletModel.cashNoteInfo;
    
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(walletId) forKey:@"walletId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(accoutId) forKey:@"accoutId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(amount) forKey:@"amount"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(cashFees) forKey:@"cashFees"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(message) forKey:@"message"];
    
    [NetWorkManager POST:kURL(@"/cash/create") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        //创建成功，验证密码没密码提醒用户去创建密码
        if (![YXWalletPasswordManager sharedYXWalletPasswordManager].isHavePassword) {
            [MBProgressHUD showSuccess:@"未设置密码请求前往设置"];
            return;
        }
        
        YXWalletCashCreateModel *model = [YXWalletCashCreateModel mj_objectWithKeyValues:responseObject];
        weakSelf.cashCreateModel = model;
        if (model.status == 200) {
            if (weakSelf.showInputPasswordViewBlock) {
                weakSelf.showInputPasswordViewBlock();
            }
        }else{
            [MBProgressHUD showError:model.msg];
        }
    
        
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"兑现失败"];
    }];
    
}

- (void)confirmToCash{
    

    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    
    NSString *accoutId = weakSelf.cashCreateModel.data.id;
    [paramDict setObject:GET_A_NOT_NIL_STRING(accoutId) forKey:@"id"];

    [NetWorkManager POST:kURL(@"/cash/confirm") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        YXWalletNomalModel *model = [YXWalletNomalModel mj_objectWithKeyValues:responseObject];
        if (model.status.intValue == 200) {
            if (weakSelf.confirmCashSuccessBlock) {
                weakSelf.confirmCashSuccessBlock();
            }
        }else{
            [MBProgressHUD showError:model.msg];
        }

   
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"兑现失败"];
        [MBProgressHUD hideHUD];
    }];
}

@end

