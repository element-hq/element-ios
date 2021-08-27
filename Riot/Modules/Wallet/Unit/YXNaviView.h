//
//  YXNaviView.h
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXNaviView : UIView
@property (nonatomic , copy)dispatch_block_t backBlock;
@property (nonatomic , copy)dispatch_block_t moreBlock;
@property (nonatomic , copy)dispatch_block_t rightLabelBlock;
@property (nonatomic , copy)NSString *title;
@property (nonatomic , copy)NSString *rightText;
@property (nonatomic , strong)UIColor *titleColor;
@property (nonatomic , assign)BOOL showBackBtn;
@property (nonatomic , assign)BOOL showMoreBtn;
@property (nonatomic , assign)BOOL showRightLabel;
@property (nonatomic , strong)UIImage *leftImage;
@property (nonatomic , strong)UIImage *rightImage;
@end

NS_ASSUME_NONNULL_END
