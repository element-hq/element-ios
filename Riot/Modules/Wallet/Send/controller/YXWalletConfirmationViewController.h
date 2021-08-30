//
//  YXWalletConfirmationViewController.h
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXWalletSendViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletConfirmationViewController : YXBaseViewController
@property (nonatomic , strong)YXWalletSendDataInfo *sendDataInfo;
@property (nonatomic , copy)NSString *naviTitle;
@property (nonatomic , copy)dispatch_block_t reloadRecordData;
@end

NS_ASSUME_NONNULL_END
