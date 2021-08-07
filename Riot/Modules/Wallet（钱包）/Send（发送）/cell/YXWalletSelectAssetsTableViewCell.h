//
//  YXWalletSelectAssetsTableViewCell.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YXWalletCoinModel.h"
#import "YXWalletMyWalletModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletSelectAssetsTableViewCell : UITableViewCell
@property (nonatomic , strong) YXWalletMyWalletRecordsItem *model;

@end

NS_ASSUME_NONNULL_END
