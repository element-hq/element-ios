//
//  YXNodeSettingTableViewCell.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseTableViewCell.h"
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeSettingTableViewCell : YXBaseTableViewCell
@property (nonatomic , strong)YXNodeConfigDataItem *model;
@property (nonatomic , strong)YXNodeListdata *nodeInfoModel;
@end

NS_ASSUME_NONNULL_END
