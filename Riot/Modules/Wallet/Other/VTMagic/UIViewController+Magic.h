//
//  UIViewController+Magic.h
//  VTMagic
//
//  Created by tianzhuo on 15/7/9.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VTMagicProtocol.h"

/**
 *  magic重用协议
 */
@protocol VTMagicReuseProtocol <NSObject>

@optional
/**
 *  控制器即将被重用时触发，由magicController的子页面控制器实现
 */
- (void)vtm_prepareForReuse;

@end

@interface UIViewController (Magic)<VTMagicReuseProtocol>

/**
 *  缓存重用标识
 */
@property (nonatomic, copy) NSString *reuseIdentifier;

/**
 *  主控制器
 */
@property (nonatomic, weak, readonly) UIViewController<VTMagicProtocol> *magicController;

@end
