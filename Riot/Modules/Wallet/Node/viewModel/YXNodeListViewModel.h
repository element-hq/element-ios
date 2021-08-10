//
//  YXNodeListViewModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletMyWalletModel.h"
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeListViewModel : YXBaseViewModel
@property (nonatomic , copy)void (^touchNodeListForDetailBlock)(YXNodeListdata *model);
@property (nonatomic , copy)void (^configNodeListForDetailBlock)(YXNodeListdata *model);
@property (nonatomic , copy)void (^requestNodeSuccessBlock)(YXNodeListModel *model);
@property (nonatomic , strong)YXNodeListModel *nodeListModel;
- (void)reloadNewData:(YXWalletMyWalletRecordsItem *)model;
@end

NS_ASSUME_NONNULL_END
