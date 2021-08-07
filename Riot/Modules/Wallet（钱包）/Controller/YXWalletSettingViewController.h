//
//  YXWalletSettingViewController.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletSettingViewController : YXBaseViewController
@property (nonatomic , assign)BOOL isWalletSetting;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
@end

NS_ASSUME_NONNULL_END
