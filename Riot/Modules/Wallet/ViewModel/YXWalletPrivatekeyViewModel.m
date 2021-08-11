//
//  YXWalletPrivatekeyViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletPrivatekeyViewModel.h"
#import "YXWalletTipCloaseTableViewCell.h"
#import "YXWalletPrivatekeyTableViewCell.h"
#import "YXWalletPrivateKeyTipTableViewCell.h"
#import "YXWalletNextTableViewCell.h"
@interface YXWalletPrivatekeyViewModel ()
@property (nonatomic , assign)NSInteger next;
@property (nonatomic , strong)YXWalletPrivateKeyDataInfo *infoModel;
@end
@implementation YXWalletPrivatekeyViewModel
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model{
    _model = model;
    self.next = 1;
    [self requestPrivateKeyWithWalletId:model.walletId andNext:self.next];

}

- (void)requestPrivateKeyWithWalletId:(NSString *)walletId andNext:(NSInteger)next{
    [MBProgressHUD showMessage:@"请求数据中..."];
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:@(next).stringValue forKey:@"next"];
    [paramDict setObject:walletId forKey:@"id"];
    [NetWorkManager GET:kURL(@"/wallet/private_key") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletPrivateKeyData *dataM = [YXWalletPrivateKeyData mj_objectWithKeyValues:responseObject];
            [weakSelf updataUIwieht:dataM.data];
        }
        [MBProgressHUD hideHUD];
   
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"请求失败"];
        [MBProgressHUD hideHUD];
    }];
}

-(void)updataUIwieht:(YXWalletPrivateKeyDataInfo *)infoModel{
    _infoModel = infoModel;
    [self.sectionItems removeAllObjects];
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    
    SCETRowItem *closeItem = [SCETRowItem rowItemWithRowData:@"请注意周围环境，以免私钥泄漏。" cellClassString:NSStringFromClass([YXWalletTipCloaseTableViewCell class])];
    closeItem.cellHeight = 25;
    [rowItems addObject:closeItem];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 30;
    [rowItems addObject:lineItem];

    YXWalletPrivateKeyModel *address = [[YXWalletPrivateKeyModel alloc]init];
    address.title = infoModel.address;
    address.des = @"地址：";
    SCETRowItem *addressItem = [SCETRowItem rowItemWithRowData:address cellClassString:NSStringFromClass([YXWalletPrivatekeyTableViewCell class])];
    addressItem.cellHeight = 76 + address.cellHeight;
    [rowItems addObject:addressItem];
    
    SCETRowItem *centerlineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    centerlineItem.cellHeight = 15;
    [rowItems addObject:centerlineItem];
    
    YXWalletPrivateKeyModel *privateKey = [[YXWalletPrivateKeyModel alloc]init];
    privateKey.title = infoModel.privateKey;
    privateKey.des = @"私钥：";
    SCETRowItem *privateKeyItem = [SCETRowItem rowItemWithRowData:privateKey cellClassString:NSStringFromClass([YXWalletPrivatekeyTableViewCell class])];
    privateKeyItem.cellHeight = 76 + privateKey.cellHeight;
    [rowItems addObject:privateKeyItem];
    
    SCETRowItem *bottomlineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    bottomlineItem.cellHeight = 37;
    [rowItems addObject:bottomlineItem];
    
    SCETRowItem *tipItem = [SCETRowItem rowItemWithRowData:@"注意：该钱包存在无数个钱包地址，点击下一个即可查看下一个地址私钥。" cellClassString:NSStringFromClass([YXWalletPrivateKeyTipTableViewCell class])];
    tipItem.cellHeight = 40;
    [rowItems addObject:tipItem];
    
    SCETRowItem *spaceItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    spaceItem.cellHeight = 25;
    [rowItems addObject:spaceItem];
    
    SCETRowItem *nextItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXWalletNextTableViewCell class])];
    nextItem.cellHeight = 40;
    [rowItems addObject:nextItem];
    
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

- (void)walletPrivateKeyNext{
    self.next += 1;
    [self requestPrivateKeyWithWalletId:_model.walletId andNext:self.next];
}

- (void)walletPrivateKeyCopy{
    UIPasteboard *pab = [UIPasteboard generalPasteboard];
    [pab setString:GET_A_NOT_NIL_STRING(_infoModel.privateKey)];
    [MBProgressHUD showSuccess:@"复制成功"];
}

@end
