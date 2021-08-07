//
//  YXWalletAddAccountEditViewModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletAccountModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAddAccountEditViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t addSuccessBlock;
@property (nonatomic , copy)dispatch_block_t callCameraBlock;
- (void)reloadNewDataWith:(YXWalletAccountBindingType)type;
//绑定账户
- (void)walleBindingAccount;
//选择图片
- (void)walletAddAccountSelectPhoto;

- (void)uploadCommunityImages:(NSArray *)data;


@end

NS_ASSUME_NONNULL_END
