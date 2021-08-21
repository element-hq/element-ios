//
//  YXWalletNoteListViewController.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXWalletMyWalletModel.h"
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletNoteListViewController : YXBaseViewController
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
@property (nonatomic , copy)void (^requestNodeSuccessBlock)(YXNodeListModel *model);
- (void)reloadNewData;
@end

NS_ASSUME_NONNULL_END
