//
//  YXWalletCreateWorldView.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletCreateWorldView : UIView
@property (nonatomic , copy)dispatch_block_t nextBlock;
@property (nonatomic , strong)NSArray *tagsArray;
@end

NS_ASSUME_NONNULL_END
