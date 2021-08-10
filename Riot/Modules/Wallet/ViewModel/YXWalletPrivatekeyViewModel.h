//
//  YXWalletPrivatekeyViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletPrivateKeyModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletPrivatekeyViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model;
- (void)closeTipView:(UITableViewCell *)cell;
- (void)walletPrivateKeyNext;
- (void)walletPrivateKeyCopy;
@end

NS_ASSUME_NONNULL_END
