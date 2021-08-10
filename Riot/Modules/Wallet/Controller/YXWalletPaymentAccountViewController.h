//
//  YXWalletPaymentAccountViewController.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
///收款账户
@interface YXWalletPaymentAccountViewController : YXBaseViewController
@property (nonatomic , copy)void (^settingDefaultSuccessBlock)(void);
@property (nonatomic , assign)BOOL isCash;//是否是兑现过来的

@end

NS_ASSUME_NONNULL_END
