//
//  YXWalletHelpWordViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletHelpWordViewModel.h"
#import "YXWalletTipCloaseTableViewCell.h"
#import "YXWalletHelpWordTableViewCell.h"
#import "YXWalletPrivateKeyTipTableViewCell.h"
#import "YXWalletCopyTableViewCell.h"
@implementation YXWalletHelpWordViewModel
- (void)reloadNewData:(NSArray *)wordArray{
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    
    SCETRowItem *closeItem = [SCETRowItem rowItemWithRowData:@"查看助记词时注意周围环境，以免助记词泄漏。" cellClassString:NSStringFromClass([YXWalletTipCloaseTableViewCell class])];
    closeItem.cellHeight = 25;
    [rowItems addObject:closeItem];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 30;
    [rowItems addObject:lineItem];

    //助记词
    SCETRowItem *helpItem = [SCETRowItem rowItemWithRowData:wordArray cellClassString:NSStringFromClass([YXWalletHelpWordTableViewCell class])];
    helpItem.cellHeight = 150;
    [rowItems addObject:helpItem];
    
    SCETRowItem *bottomlineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    bottomlineItem.cellHeight = 37;
    [rowItems addObject:bottomlineItem];
    

    SCETRowItem *tipItem = [SCETRowItem rowItemWithRowData:@"注意：助记词是用户钱包的唯一标识，不能分享给他人，严格保密。掌握该助记词的用户即可控制该钱包。" cellClassString:NSStringFromClass([YXWalletPrivateKeyTipTableViewCell class])];
    tipItem.cellHeight = 40;
    [rowItems addObject:tipItem];
    
    SCETRowItem *spaceItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    spaceItem.cellHeight = 25;
    [rowItems addObject:spaceItem];
    
    SCETRowItem *copyItem = [SCETRowItem rowItemWithRowData:@"复制助记词" cellClassString:NSStringFromClass([YXWalletCopyTableViewCell class])];
    copyItem.cellHeight = 40;
    [rowItems addObject:copyItem];
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadData) {
        self.reloadData();
    }

}

- (void)closeTipView:(UITableViewCell *)cell{

    [self.dataSource.sectionItems enumerateObjectsUsingBlock:^(SCETSectionItem * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        [section.rowItems enumerateObjectsUsingBlock:^(SCETRowItem * _Nonnull rowItem, NSUInteger idx, BOOL * _Nonnull stop) {
            SCETRowItem *rowM = rowItem;
            if ([rowM.cellClassString isEqualToString:NSStringFromClass([cell class])]) {
                [section.rowItems removeObject:rowM];
            }
        }];
    }];
    
    if (self.reloadData) {
        self.reloadData();
    }
    
}

- (void)walletCopyHelpWord{
    UIPasteboard *pab = [UIPasteboard generalPasteboard];
    [pab setString:GET_A_NOT_NIL_STRING(self.helpWord)];
    [MBProgressHUD showSuccess:@"复制成功"];
}
@end
