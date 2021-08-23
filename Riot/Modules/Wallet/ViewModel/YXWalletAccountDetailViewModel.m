//
//  YXWalletAccountDetailViewModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAccountDetailViewModel.h"
#import "YXWalletAccountTableViewCell.h"
#import "YXWalletAccountDeatilTableViewCell.h"
#import "YXWalletCopyTableViewCell.h"
#import "YXWalletAccountModel.h"

@interface YXWalletAccountDetailViewModel ()
@property (nonatomic , strong)YXWalletPaymentAccountRecordsItem *model;
@end

@implementation YXWalletAccountDetailViewModel

- (void)reloadNewData:(YXWalletPaymentAccountRecordsItem *)model{
    self.model = model;
    model.isDetail = YES;
    NSMutableArray<SCETRowItem *> *rowItems = [NSMutableArray new];
    
    SCETRowItem *lineItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    lineItem.cellHeight = 30;
    [rowItems addObject:lineItem];
    
    SCETRowItem *accountItem = [SCETRowItem rowItemWithRowData:model cellClassString:NSStringFromClass([YXWalletAccountTableViewCell class])];
    accountItem.cellHeight = 100;
    [rowItems addObject:accountItem];
    
    SCETRowItem *centerItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    centerItem.cellHeight = 40;
    [rowItems addObject:centerItem];
    
    //只有银行卡有开户行
    if ([model.type isEqualToString:@"1"]) {
        //开户行
        YXWalletPaymentAccountRecordsItem *khhObj = [[YXWalletPaymentAccountRecordsItem alloc]init];
        khhObj.title = @"开户行";
        khhObj.options = model.options;
        
        SCETRowItem *khhItem = [SCETRowItem rowItemWithRowData:khhObj cellClassString:NSStringFromClass([YXWalletAccountDeatilTableViewCell class])];
        khhItem.cellHeight = 50;
        [rowItems addObject:khhItem];
    }
    
    
    //手机号码
    YXWalletPaymentAccountRecordsItem *iphonObj = [[YXWalletPaymentAccountRecordsItem alloc]init];
    iphonObj.title = [model.type isEqualToString:@"1"] ? @"手机号码" : @"用户账户";
    iphonObj.options = model.options;
    
    SCETRowItem *iphonItem = [SCETRowItem rowItemWithRowData:iphonObj cellClassString:NSStringFromClass([YXWalletAccountDeatilTableViewCell class])];
    iphonItem.cellHeight = 50;
    [rowItems addObject:iphonItem];
    
    SCETRowItem *bottomItem = [SCETRowItem rowItemWithRowData:@"test cell" cellClassString:NSStringFromClass([YXLineTableViewCell class])];
    bottomItem.cellHeight = 60;
    [rowItems addObject:bottomItem];
    
  
    SCETRowItem *copyItem = [SCETRowItem rowItemWithRowData:@"解除绑定" cellClassString:NSStringFromClass([YXWalletCopyTableViewCell class])];
    copyItem.cellHeight = 40;
    [rowItems addObject:copyItem];

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
    
}

//解除绑定
- (void)walletAddAccountUnBinding{
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];

    [paramDict setObject:self.model.ID forKey:@"id"];
    
    [NetWorkManager DELETE:kURL(@"/account") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *dic = responseObject;
            YXWalletAddAccountModel *model = [YXWalletAddAccountModel mj_objectWithKeyValues:dic];
            if (model.status == 200) {
                if (self.unBindingSuccessBlock) {
                    self.unBindingSuccessBlock();
                }
            }else{
                [MBProgressHUD showError:model.msg];
            }
        }

    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"解除失败"];
    }];
    
}

@end
