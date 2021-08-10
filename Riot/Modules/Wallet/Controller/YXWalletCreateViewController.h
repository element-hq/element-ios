//
//  YXWalletCreateViewController.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXWalletCoinModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletCreateViewController : YXBaseViewController
@property (nonatomic , strong)YXWalletCoinDataModel *coinModel;
@property (nonatomic , assign)BOOL isCreate;//是否是创建
@end

NS_ASSUME_NONNULL_END
