//
//  YXWalletSendViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletSendModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletSendViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t showSelectAssetsViewBlock;
@property (nonatomic , copy)dispatch_block_t reloadContactDataBlock;
@property (nonatomic , copy)dispatch_block_t jumpContactDetailBlock;
@property (nonatomic , copy)dispatch_block_t jumpContactViewBlock;
@property (nonatomic , copy)dispatch_block_t jumpScanViewBlock;
@property (nonatomic , copy)dispatch_block_t showInputPasswordViewBlock;
@property (nonatomic , copy)dispatch_block_t confirmPaySuccessBlock;
@property (nonatomic , copy)dispatch_block_t confirmPayFailError;
@property (nonatomic , copy)void (^nextBlock)(YXWalletSendDataInfo *model);
@property (nonatomic , copy)void (^selectFirendBlock)(NSString *walletAddr);
- (void)nextSendOperation;
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model;
- (void)reloadContactData:(YXWalletMyWalletRecordsItem *)model;
- (void)reloadConfirmationData:(YXWalletSendDataInfo *)model;
- (void)walletSendConfirmPay;
- (void)confirmPay;
@end

NS_ASSUME_NONNULL_END
