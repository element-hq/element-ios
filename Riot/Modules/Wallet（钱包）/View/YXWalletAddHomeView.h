//
//  YXWalletAddHomeView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletAddHomeView : UIView
@property (nonatomic , copy)dispatch_block_t touchBlock;
@property (nonatomic , copy)NSString *title;
@property (nonatomic , copy)NSString *desc;
@property (nonatomic , strong)UIImage *image;
@end

NS_ASSUME_NONNULL_END
