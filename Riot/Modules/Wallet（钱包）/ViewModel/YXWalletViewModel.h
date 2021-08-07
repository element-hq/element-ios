//
//  YXWalletViewModel.h
//  UniversalApp
//
//  Created by liaoshen on 2021/6/22.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletCoinModel.h"
#import "YXWalletMyWalletModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletViewModel : YXBaseViewModel
@property (nonatomic , strong)YXWalletCoinModel *coinModel;
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t showAddViewBlock;
@property (nonatomic , copy)dispatch_block_t jumpSendEditDetailBlock;
@property (nonatomic , copy)dispatch_block_t jumpReceiveCodeBlock;
@property (nonatomic , copy)dispatch_block_t jumpCashVCDetailBlock;
@property (nonatomic , copy)void (^selectIndexBlock)(YXWalletMyWalletRecordsItem *model);
- (void)walletSecretCode;
- (void)reloadNewData;
- (void)reloadMoreData;
//查询所有币种信息
- (void)getAllCoinInfo;
- (void)getJumpWalletCashDataWalleId:(NSString *)walletId
                            Complete:(void (^)(YXWalletMyWalletRecordsItem *walletModel))complete
                             failure:(void (^)(void))failure;
@end

NS_ASSUME_NONNULL_END
