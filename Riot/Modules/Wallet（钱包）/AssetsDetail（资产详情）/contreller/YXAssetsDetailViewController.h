//
//  YXAssetsDetailViewController.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXWalletMyWalletModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXAssetsDetailViewController : YXBaseViewController

@property (nonatomic , copy)NSString *titleName;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
@end

NS_ASSUME_NONNULL_END
