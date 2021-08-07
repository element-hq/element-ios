//
//  YXWalletAssetsSelectView.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YXWalletCoinModel.h"
#import "YXWalletMyWalletModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAssetsSelectView : UIView
@property (nonatomic , copy)void (^selectAssetsBlock)(YXWalletMyWalletRecordsItem *model);
@property (nonatomic , copy)void (^requestAssetsSuccessBlock)(YXWalletMyWalletRecordsItem *model);
@property (nonatomic , strong) NSMutableArray <YXWalletMyWalletRecordsItem *> *sectionItems;
- (void)refreshHeaderAction;
@end

NS_ASSUME_NONNULL_END
