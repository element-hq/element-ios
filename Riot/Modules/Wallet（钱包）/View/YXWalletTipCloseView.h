//
//  YXWalletTipCloseView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletTipCloseView : UIView
@property (nonatomic , copy)NSString *title;
@property (nonatomic , copy)dispatch_block_t closeBlock;
@end

NS_ASSUME_NONNULL_END
