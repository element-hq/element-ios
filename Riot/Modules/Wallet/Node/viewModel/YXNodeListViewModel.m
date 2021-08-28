//
//  YXNodeListViewModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeListViewModel.h"
#import "YXNodeNoDetailTableViewCell.h"
#import "YXNodeListItemTableViewCell.h"
#import "YXNodeSelectTableViewCell.h"
@implementation YXNodeListViewModel
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model{
    
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:model.walletId forKey:@"walletId"];
    [paramDict setObject:@(model.noteType) forKey:@"type"];
    [NetWorkManager GET:kURL(@"/node/list") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXNodeListModel *detailList = [YXNodeListModel mj_objectWithKeyValues:responseObject];
            if (detailList.status.intValue == 200) {
                weakSelf.nodeListModel = detailList;
                [weakSelf setupListHeadData:detailList.data and:model];
            }
        }
        
    } failure:^(NSError * _Nonnull error) {
            
    }];
    
   
}

- (void)setupListHeadData:(NSArray *)array and:(YXWalletMyWalletRecordsItem *)model{
    [self.sectionItems removeAllObjects];
    YXWeakSelf
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    if (model.noteType == YXWalletNoteTypeConfig || model.noteType == YXWalletNoteTypeNormal || model.noteType == YXWalletNoteTypeDrops) {
        SCETRowItem *nodeSelectItem = [SCETRowItem rowItemWithRowData:model cellClassString:NSStringFromClass([YXNodeSelectTableViewCell class])];
        nodeSelectItem.cellHeight = 50;
        [rowItems addObject:nodeSelectItem];
    }else{
        SCETRowItem *lienItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
        lienItem.cellHeight = 8;
        [rowItems addObject:lienItem];
    }
    
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCETRowItem *nodeListItem = [SCETRowItem rowItemWithRowData:obj cellClassString:NSStringFromClass([YXNodeListItemTableViewCell class])];
        nodeListItem.cellHeight = 96;
        [rowItems addObject:nodeListItem];
        
        SCETRowItem *lienItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
        lienItem.cellHeight = 20;
        [rowItems addObject:lienItem];
        
    }];
    
    
    if (array.count == 0) {
        //空白
        SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXNodeNoDetailTableViewCell class])];
        lineItem.cellHeight = SCREEN_HEIGHT;
        [rowItems addObject:lineItem];
    }

    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.requestNodeSuccessBlock) {
        self.requestNodeSuccessBlock(self.nodeListModel);
    }
    
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
    
    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXNodeListItemTableViewCell.class)]) {
        YXNodeListdata *model = (YXNodeListdata *)rowItem.rowData;
        
        if (!model.configuration) return;//未配置不能进入详情页
        model.armingFlag = @"1";
        if (self.touchNodeListForDetailBlock) {
            self.touchNodeListForDetailBlock(model);
        }

    }
    
}
@end
