//
//  YXNodeDetailViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailViewModel.h"
#import "YXNodeDetailHeadTableViewCell.h"
#import "YXNodeDetailFooterTableViewCell.h"
#import "YXNodeDetailModel.h"
#import "YXNodeArmingFlagTableViewCell.h"

@interface YXNodeDetailViewModel ()
@property (nonatomic , strong)YXNodeDetailModel *detailModel;
@end

@implementation YXNodeDetailViewModel
- (void)reloadNewData:(YXNodeListdata *)model{
 
    [self.sectionItems removeAllObjects];
    
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];

    NSString *headTitle = [model.armingFlag isEqualToString:@"0"] ? @"解冻质押" : @"重新激活";
    
    SCETRowItem *headItem = [SCETRowItem rowItemWithRowData:headTitle cellClassString:NSStringFromClass([YXNodeDetailHeadTableViewCell class])];
    headItem.cellHeight = 260;
    [rowItems addObject:headItem];
    
    
    if ([model.armingFlag isEqualToString:@"0"]) {
        SCETRowItem *armingFlagtem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXNodeArmingFlagTableViewCell class])];
        armingFlagtem.cellHeight = 260;
        [rowItems addObject:armingFlagtem];
    }else{
        NSMutableArray <YXNodeDetailModel *>* editUIArray = [self.detailModel getCellArray:model];
        
        [editUIArray enumerateObjectsUsingBlock:^(YXNodeDetailModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SCETRowItem *detailItem = [SCETRowItem rowItemWithRowData:obj cellClassString:obj.cellName];
            detailItem.cellHeight = obj.cellHeight;
            [rowItems addObject:detailItem];
        }];
    }

    
    SCETRowItem *footertem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXNodeDetailFooterTableViewCell class])];
    footertem.cellHeight = 37;
    [rowItems addObject:footertem];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 40;
    [rowItems addObject:lineItem];
    
    SCETSectionItem *totalCountsectionItem = [SCETSectionItem sc_sectionItemWithRowItems:rowItems];
    [self.sectionItems addObject:totalCountsectionItem];
    
    [self resetDataSource:self.sectionItems];
    
    if (self.reloadData) {
        self.reloadData();
    }
    
}

-(YXNodeDetailModel *)detailModel{
    if (!_detailModel) {
        _detailModel = [[YXNodeDetailModel alloc]init];
    }
    return _detailModel;
}

- (void)getPledegTxData:(YXNodeListdata *)model{
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(model.walletId) forKey:@"walletId"];
    [NetWorkManager GET:kURL(@"/node/pledeg_tx") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXNodeConfigModelPledeg *detailList = [YXNodeConfigModelPledeg mj_objectWithKeyValues:responseObject];
            if (detailList.status == 200) {
                weakSelf.pledegModel = detailList;
            }
        }
        
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

- (void)getNodeInfo:(YXNodeListdata *)model{
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(model.ID) forKey:@"id"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(model.walletId) forKey:@"walletId"];
    [NetWorkManager GET:kURL(@"/node/info") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *dic = responseObject[@"data"];
            YXNodeListdata *detailList = [YXNodeListdata mj_objectWithKeyValues:dic];
            weakSelf.nodeInfoModel = detailList;
        }
        
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

- (void)configNodeActivityWalletId:(NSString *)walletId txid:(NSString *)txid vout:(NSString *)vout ip:(NSString *)ip privateKey:(NSString *)privateKey Complete:(void (^)(void))complete{
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(walletId) forKey:@"walletId"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(txid) forKey:@"txid"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(vout) forKey:@"vout"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(ip) forKey:@"ip"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(privateKey) forKey:@"privateKey"];
    [NetWorkManager POST:kURL(@"/node/activity") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXNodeActivityModel *model = [YXNodeActivityModel mj_objectWithKeyValues:responseObject];
            if (model.status.intValue == 200) {
                if (complete) {
                    complete();
                }
            }
  
        }else{
            [MBProgressHUD showError:@"激活失败"];
        }
        
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"激活失败"];
    }];
    
}

///解冻质押
- (void)pledgeUnfreezeNode:(YXNodeListdata *)model Complete:(nonnull void (^)(void))complete{
    [MBProgressHUD showMessage:@""];
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:GET_A_NOT_NIL_STRING(model.ID) forKey:@"id"];
    [paramDict setObject:GET_A_NOT_NIL_STRING(model.ip) forKey:@"ip"];
    [NetWorkManager POST:kURL(@"/node/pledge_unfreeze") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            if (complete) {
                complete();
            }
        }
        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
    }];
}

@end

