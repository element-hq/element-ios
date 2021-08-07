//
//  YXWalletContactViewController.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXWalletSendViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletContactViewController : YXBaseViewController
@property (nonatomic , copy)void (^selectFirendBlock)(NSString *walletAddr);
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *currentSelectModel;
@end

NS_ASSUME_NONNULL_END
