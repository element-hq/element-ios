//
//  YXNodeSettingView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeSettingView : UIView
@property (nonatomic , copy)dispatch_block_t backBlock;
@property (nonatomic , copy)dispatch_block_t moreBlock;
@property (nonatomic , copy)void (^selectTXblock)(YXNodeConfigDataItem *model);
@property (nonatomic , copy)void (^selectNodeInfoblock)(YXNodeListdata *model);
@property (nonatomic , strong)YXNodeConfigModelPledeg *pledegModel;
@property (nonatomic , strong)YXNodeListdata *nodeInfoModel;
@end

NS_ASSUME_NONNULL_END
