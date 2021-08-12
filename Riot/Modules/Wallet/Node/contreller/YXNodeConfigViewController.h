//
//  YXNodeConfigViewController.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewController.h"
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeConfigViewController : YXBaseViewController
@property (nonatomic , strong)YXNodeListdata *nodeListModel;
@property (nonatomic , copy)dispatch_block_t reloadDataBlock;
@end

NS_ASSUME_NONNULL_END
