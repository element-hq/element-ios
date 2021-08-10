//
//  YXWalletAddView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YXWalletCoinModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAddView : UIView
@property (nonatomic , strong)YXWalletCoinModel *coinModel;
@property (nonatomic , copy)void (^selectAddWalletItemBlock)(YXWalletCoinDataModel * model);
@end

NS_ASSUME_NONNULL_END
