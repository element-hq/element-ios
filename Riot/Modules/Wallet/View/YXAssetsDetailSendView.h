//
//  YXAssetsDetailSendView.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXAssetsDetailSendView : UIView
@property (nonatomic , copy)dispatch_block_t receiveBlock;
@property (nonatomic , copy)dispatch_block_t sendBlock;
@end

NS_ASSUME_NONNULL_END
