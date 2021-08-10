//
//  YXWalletPaymentAccountViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletPaymentAccountModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletPaymentAccountViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)void (^settingDefaultSuccessBlock)(void);
@property (nonatomic , copy)void (^getDefaultAccountBlock)(YXWalletPaymentAccountRecordsItem *model);
@property (nonatomic , copy)void (^settingAccountNotiBlock)(void);
@property (nonatomic , copy)void (^touchSettingBlock)(YXWalletPaymentAccountRecordsItem *model);
- (void)reloadNewData;
- (void)walletAccountSettingDefault:(YXWalletPaymentAccountRecordsItem *)model;
@end

NS_ASSUME_NONNULL_END
