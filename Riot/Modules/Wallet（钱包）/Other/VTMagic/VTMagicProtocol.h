//
//  VTMagicProtocol.h
//  VTMagic
//
//  Created by tianzhuo on 15/7/11.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//
//  private protocol

#import <Foundation/Foundation.h>
#import "VTEnumType.h"

@class VTMagicView;
@protocol VTMagicProtocol <NSObject>

@required
/**
 *  当前页面索引
 */
- (NSInteger)currentPage;
/**
 *  当前页面索引的setter方法，外部禁止直接修改
 */
- (void)setCurrentPage:(NSInteger)currentPage;

/**
 *  当前页面控制器
 */
- (__kindof UIViewController *)currentViewController;
/**
 *  当前页面控制器的setter方法
 *
 *  @param currentViewController 当前页面控制器，外部禁止直接修改
 */
- (void)setCurrentViewController:(UIViewController *)currentViewController;

/**
 *  magicController的显示状态
 *
 *  @return 生命周期状态
 */
- (VTAppearanceState)appearanceState;

@optional
/**
 *  任何magicController默认都会有对应的magicView
 */
- (VTMagicView *)magicView;

@end
