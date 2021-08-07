//
//  YXAssetsDetailViewModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXAssetsDetailViewModel.h"
#import "YXAssetsDetailHeadTableViewCell.h"
#import "YXWalletAddAccountTitleCell.h"
#import "YXAssetsDetailListTableViewCell.h"

@interface YXAssetsDetailViewModel ()
@property(nonatomic) NSInteger currentPage;
@end

@implementation YXAssetsDetailViewModel
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model{
    self.currentPage = 1;
    [self.sectionItems removeAllObjects];
    
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"walletId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/transaction/record") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXAssetsDetailListModel *detailList = [YXAssetsDetailListModel mj_objectWithKeyValues:responseObject];
            if (detailList.status == 200) {
                [weakSelf setupListHeadData:detailList.data.records andunProcess:detailList.data.unProcess andModel:model];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
    
    
   
}

- (void)reloadMoreData:(YXWalletMyWalletRecordsItem *)model{
    
    self.currentPage += 1;
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"walletId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/transaction/record") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXAssetsDetailListModel *detailList = [YXAssetsDetailListModel mj_objectWithKeyValues:responseObject];
            if (detailList.status == 200) {
                [weakSelf setupListHeadData:detailList.data.records andunProcess:detailList.data.unProcess andModel:model];
            }
        }
   
    } failure:^(NSError * _Nonnull error) {
            
    }];
    
}

- (void)setupListHeadData:(NSArray <YXAssetsDetailRecordsItem *>*)array andunProcess:(NSArray <YXAssetsDetailRecordsItem *>*)unProcess andModel:(YXWalletMyWalletRecordsItem *)model{
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    if (self.currentPage == 1) {
        //头部
        SCETRowItem *headItem = [SCETRowItem rowItemWithRowData:model cellClassString:NSStringFromClass([YXAssetsDetailHeadTableViewCell class])];
        headItem.cellHeight = 116;
        [rowItems addObject:headItem];
        
        SCETRowItem *titleItem = [SCETRowItem rowItemWithRowData:@"交易记录" cellClassString:NSStringFromClass([YXWalletAddAccountTitleCell class])];
        titleItem.cellHeight = 57;
        [rowItems addObject:titleItem];
        
        [unProcess enumerateObjectsUsingBlock:^(YXAssetsDetailRecordsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            SCETRowItem *detailListItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXAssetsDetailListTableViewCell class])];
            detailListItem.cellHeight = 80;
            [rowItems addObject:detailListItem];
            
        }];
        
    }

    [array enumerateObjectsUsingBlock:^(YXAssetsDetailRecordsItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        SCETRowItem *detailListItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXAssetsDetailListTableViewCell class])];
        detailListItem.cellHeight = 80;
        [rowItems addObject:detailListItem];
        
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
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXAssetsDetailListTableViewCell.class)]) {
        if (self.touchAssetsDetailItemBlock) {
            self.touchAssetsDetailItemBlock(rowItem.rowData);
        }

    }
    
}

- (void)jumpNodeListVc{
    if (self.jumpNodeListVcBlock) {
        self.jumpNodeListVcBlock();
    }
}
@end
