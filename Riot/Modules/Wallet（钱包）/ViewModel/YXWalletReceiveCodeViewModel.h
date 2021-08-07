//
//  YXWalletReceiveCodeViewModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletReceiveCodeViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t refreshAddressBlock;
@property (nonatomic , copy)dispatch_block_t showSelectAssetsViewBlock;
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model;
@end

NS_ASSUME_NONNULL_END
