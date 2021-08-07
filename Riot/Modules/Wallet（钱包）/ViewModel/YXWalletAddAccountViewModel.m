//
//  YXWalletAddAccountViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountViewModel.h"
#import "YXWalletAddAccountTableViewCell.h"
@implementation YXWalletAddAccountViewModel
- (void)reloadNewData{
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    

    for (int i = 0; i < 3 ; i ++) {
        
        SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
        lineItem.cellHeight = 30;
        [rowItems addObject:lineItem];
        NSString *image;
        if (i == 0) {
            image = @"card_add";
        }else if (i == 1){
            image = @"zhifubao_add";
        }else if (i == 2){
            image = @"wechat_add";
        }
        SCETRowItem *accountItem = [SCETRowItem rowItemWithRowData:image cellClassString:NSStringFromClass([YXWalletAddAccountTableViewCell class])];
        accountItem.cellHeight = 50;
        [rowItems addObject:accountItem];
        
    }
    
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
    YXWalletAccountBindingType type;
    NSString *rowData = (NSString *)rowItem.rowData;
    if ([rowData isEqualToString:@"card_add"]) {
        type =  YXWalletAccountCardType ;
    }else if ([rowData isEqualToString:@"zhifubao_add"]){
        type = YXWalletAccountZFBType;
    }else if ([rowData isEqualToString:@"wechat_add"]){
        type = YXWalletAccountWeCharType;
    }

    
    if ([rowItem.cellClassString isEqualToString:NSStringFromClass(YXWalletAddAccountTableViewCell.class)]) {

        if (self.touchEditAccountBlock) {
            self.touchEditAccountBlock(type);
        }

    }
    
}

@end
