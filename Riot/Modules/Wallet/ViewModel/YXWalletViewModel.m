//
//  YXWalletViewModel.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/22.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXWalletViewModel.h"
#import "YXWAlletHeadTableViewCell.h"
#import "YXWalletAddTableViewCell.h"
#import "YXWalletAssetsTableViewCell.h"
#import "YXLineTableViewCell.h"
#import "YXWalletPasswordManager.h"
@interface YXWalletViewModel ()
@property(nonatomic , assign) NSInteger currentPage;
@end

@implementation YXWalletViewModel
- (void)reloadNewData{
    
    self.currentPage = 1;
    [self.sectionItems removeAllObjects];
    
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/wallet/all_wallet") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletModel *myWalletModel = [YXWalletMyWalletModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf setupListHeadData:myWalletModel.data.records];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
    
}

- (void)reloadMoreData{
    self.currentPage += 1;
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/wallet/all_wallet") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletModel *myWalletModel = [YXWalletMyWalletModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf setupListHeadData:myWalletModel.data.records];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

- (void)setupListHeadData:(NSArray <YXWalletMyWalletRecordsItem *>*)array{
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    if (self.currentPage == 1) {
        //头部
        SCETRowItem *headItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXWAlletHeadTableViewCell class])];
        headItem.cellHeight = 140 + 88;
        [rowItems addObject:headItem];
        
        //添加资产
        SCETRowItem *addItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXWalletAddTableViewCell class])];
        addItem.cellHeight = 65;
        [rowItems addObject:addItem];
        
        //资产列表
        [array enumerateObjectsUsingBlock:^(YXWalletMyWalletRecordsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SCETRowItem *assetsItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXWalletAssetsTableViewCell class])];
            assetsItem.cellHeight = 60;
            [rowItems addObject:assetsItem];
            
            SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
            lineItem.cellHeight = 10;
            [rowItems addObject:lineItem];
        }];
        
    }else{
        
        //资产列表
        [array enumerateObjectsUsingBlock:^(YXWalletMyWalletRecordsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SCETRowItem *assetsItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXWalletAssetsTableViewCell class])];
            assetsItem.cellHeight = 60;
            [rowItems addObject:assetsItem];
            
            SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
            lineItem.cellHeight = 10;
            [rowItems addObject:lineItem];
        }];
    }
    
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

- (void)getAllCoinInfo{
    YXWeakSelf
    [NetWorkManager GET:kURL(@"/config/all") parameters:@{} success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletCoinModel *coinModel = [YXWalletCoinModel mj_objectWithKeyValues:responseObject];
            weakSelf.coinModel = coinModel;
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
    
}

- (void)getJumpWalletCashDataWalleId:(NSString *)walletId Complete:(void (^)(YXWalletMyWalletRecordsItem * _Nonnull))complete failure:(nonnull void (^)(void))failure{
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:walletId forKey:@"id"];
    
    [NetWorkManager GET:kURL(@"/wallet/jump_cash") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletJumpModel *model = [YXWalletMyWalletJumpModel mj_objectWithKeyValues:responseObject];
            if (complete) {
                complete(model.data);
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
        if (failure) {
            failure();
        }
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
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletAssetsTableViewCell.class)]) {
        
        
        if (self.selectIndexBlock) {
            self.selectIndexBlock(rowItem.rowData);
        }

    }
    
}

- (void)walletSecretCode{
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [NetWorkManager GET:kURL(@"/wallet/secret_code") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletPasswordModel *model = [YXWalletPasswordModel mj_objectWithKeyValues:responseObject];
            [YXWalletPasswordManager sharedYXWalletPasswordManager].model = model;
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

@end
