//
//  YXWalletSettingViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingViewModel.h"
#import "YXLineTableViewCell.h"
#import "YXWalletSettingItemTableViewCell.h"

@interface YXWalletSettingViewModel ()
@property (nonatomic , strong)YXWalletSettingModel *settingModel;
@end

@implementation YXWalletSettingViewModel
- (void)reloadNewData:(BOOL)isWalletSetting andModel:(nonnull YXWalletMyWalletRecordsItem *)model{
    _model = model;
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 15;
    [rowItems addObject:lineItem];
    
    //设置列表
    NSMutableArray *settingArray = [self.settingModel getSettingData:isWalletSetting];
    [settingArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCETRowItem *settingItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXWalletSettingItemTableViewCell class])];
        settingItem.cellHeight = 50;
        [rowItems addObject:settingItem];
        
    }];
    
    SCETRowItem *centerlineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    centerlineItem.cellHeight = 30;
    [rowItems addObject:centerlineItem];
    
    //删除
    NSMutableArray *deleteArray = [self.settingModel getDeleteData:isWalletSetting];
    [deleteArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YXWalletSettingModel *settingM = (YXWalletSettingModel *)obj;
        settingM.walletModel = model;
        
        SCETRowItem *settingItem = [SCETRowItem rowItemWithRowData:settingM cellClassString:NSStringFromClass([YXWalletSettingItemTableViewCell class])];
        settingItem.cellHeight = 50;
        [rowItems addObject:settingItem];
        
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
    
    
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletSettingItemTableViewCell.class)]) {
        YXWalletSettingModel *model = (YXWalletSettingModel *)rowItem.rowData;
        
        if (self.touchSettingBlock) {
            self.touchSettingBlock(model);
        }

    }
    
}

//获取私钥
- (void)getWalletHelpWord:(NSString *)walletId complete:(nullable void (^)(NSDictionary *responseObject))complete{
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:walletId forKey:@"id"];
    [NetWorkManager GET:kURL(@"/wallet/show_mnemonic") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if (complete) {
            complete(responseObject);
        }
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

//删除钱包
- (void)deleteWalletHelpWord:(NSString *)walletId complete:(nullable void (^)(NSDictionary *responseObject))complete{
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:walletId forKey:@"id"];
    [NetWorkManager DELETE:kURL(@"/wallet/delete_wallet") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if (complete) {
            complete(responseObject);
        }
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"删除失败"];
    }];
    
}


-(YXWalletSettingModel *)settingModel{
    if (!_settingModel) {
        _settingModel = [[YXWalletSettingModel alloc]init];
    }
    return _settingModel;
}

- (void)walletChangePassword:(NSString *)userId
                    Password:(NSString *)password
                    complete:(nullable void (^)(NSDictionary *responseObject))complete{
    [MBProgressHUD showMessage:@"修改中..."];
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:userId forKey:@"userId"];
    [paramDict setObject:[Tool stringToMD5:password] forKey:@"password"];
    [NetWorkManager POST:kURL(@"/wallet/password") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if (complete) {
            complete(responseObject);
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        [MBProgressHUD showError:@"修改失败"];
    }];
}

@end
