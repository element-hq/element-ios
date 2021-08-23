//
//  YXWalletReceiveCodeViewModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletReceiveCodeViewModel.h"
#import "YXWalletCodeAssetsSelectCell.h"
#import "YXWalletCodeTableViewCell.h"
@implementation YXWalletReceiveCodeViewModel
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model{
    
    [MBProgressHUD showMessage:@""];
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"id"];
    [NetWorkManager GET:kURL(@"/wallet/address") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletAddressModel *myWalletModel = [YXWalletMyWalletAddressModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf updataUIWith:model andaddress:myWalletModel.data];
            }else{
                [MBProgressHUD showError:@"接口请求报错，稍后再试"];
            }
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
    }];
    
}

- (void)refreshAddress:(YXWalletMyWalletRecordsItem *)model{
    [MBProgressHUD showMessage:@""];
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"id"];
    [NetWorkManager GET:kURL(@"/wallet/new_address") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletAddressModel *myWalletModel = [YXWalletMyWalletAddressModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf updataUIWith:model andaddress:myWalletModel.data];
            }else{
                [MBProgressHUD showError:@"接口请求报错，稍后再试"];
            }
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
    }];
    
}

- (void)updataUIWith:(YXWalletMyWalletRecordsItem *)model andaddress:(NSString *)address{
    [self.sectionItems removeAllObjects];
    model.address = address;
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 10;
    [rowItems addObject:lineItem];
    
    SCETRowItem *selectItem = [SCETRowItem rowItemWithRowData:model cellClassString:NSStringFromClass([YXWalletCodeAssetsSelectCell class])];
    selectItem.cellHeight = 60;
    [rowItems addObject:selectItem];
    
    
    SCETRowItem *bottomItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    bottomItem.cellHeight = 15;
    [rowItems addObject:bottomItem];
    
    SCETRowItem *codeItem = [SCETRowItem rowItemWithRowData:model cellClassString:NSStringFromClass([YXWalletCodeTableViewCell class])];
    codeItem.cellHeight = 402;
    [rowItems addObject:codeItem];
    
    
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

    }
}

@end
