//
//  YXWalletAddAccountViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletAccountModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAddAccountViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)void (^touchEditAccountBlock)(YXWalletAccountBindingType type);
- (void)reloadNewData;
@end

NS_ASSUME_NONNULL_END
