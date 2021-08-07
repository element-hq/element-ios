//
//  YXNodeConfigView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeConfigView : UIView
@property (nonatomic , copy)dispatch_block_t pledgeDealBlock;
@property (nonatomic , copy)dispatch_block_t mainNodeBlock;
@property (nonatomic , copy)dispatch_block_t activationBlock;
@property (nonatomic , copy)NSString *pledgeText;
@property (nonatomic , copy)NSString *nodeText;

@property (nonatomic , strong)UILabel *sendLabel;
@end

NS_ASSUME_NONNULL_END
