//
//  YXWalletAccountDetailViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletPaymentAccountModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAccountDetailViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t unBindingSuccessBlock;
- (void)walletAddAccountUnBinding;
- (void)reloadNewData:(YXWalletPaymentAccountRecordsItem *)model;

@end

NS_ASSUME_NONNULL_END
