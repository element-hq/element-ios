//
//  YXWalletCashViewModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletMyWalletModel.h"
#import "YXWalletPaymentAccountModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletCashViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t failDataBlock;
@property (nonatomic , copy)dispatch_block_t showSelectAssetsViewBlock;
@property (nonatomic , copy)dispatch_block_t showAddCardBlock;//选择收款方式
@property (nonatomic , copy)dispatch_block_t showInputPasswordViewBlock;
@property (nonatomic , copy)dispatch_block_t confirmCashSuccessBlock;//确认兑现成功
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
- (void)reloadAddCardData;
- (void)reloadRecordData:(YXWalletMyWalletRecordsItem *)model;
- (void)reloadMoreRecordData:(YXWalletMyWalletRecordsItem *)model;
- (void)getCurrentAcountData:(YXWalletMyWalletRecordsItem *)model;
//确认兑现
- (void)walletConfirmToCash;
- (void)confirmToCash;
@end

NS_ASSUME_NONNULL_END
