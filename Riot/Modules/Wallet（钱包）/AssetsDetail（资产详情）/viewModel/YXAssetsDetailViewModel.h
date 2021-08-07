//
//  YXAssetsDetailViewModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletMyWalletModel.h"
#import "YXAssetsDetailListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXAssetsDetailViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t jumpNodeListVcBlock;
@property (nonatomic , copy)void (^touchAssetsDetailItemBlock)(YXAssetsDetailRecordsItem *model);
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model;
- (void)reloadMoreData:(YXWalletMyWalletRecordsItem *)model;

- (void)jumpNodeListVc;
@end

NS_ASSUME_NONNULL_END
