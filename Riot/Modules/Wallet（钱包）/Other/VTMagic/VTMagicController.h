//
//  VTMagicController.h
//  VTMagicView
//
//  Created by tianzhuo on 14-11-11.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+Magic.h"
#import "VTMagicView.h"
#import "VTCommon.h"

@interface VTMagicController : UIViewController<VTMagicViewDelegate,VTMagicViewDataSource,VTMagicProtocol>

/**
 *  magic view，等同于self.view
 */
@property (nonatomic, strong) VTMagicView *magicView;

/**
 *  当前页面对应的索引
 */
@property (nonatomic, assign) NSUInteger currentPage;

/**
 *  生命周期状态
 */
@property (nonatomic, assign) VTAppearanceState appearanceState;

/**
 *  当前显示的控制器
 */
@property (nonatomic, strong) __kindof UIViewController *currentViewController;

/**
 *  屏幕上可见的控制器
 */
@property (nonatomic, strong, readonly) NSArray<__kindof UIViewController *> *viewControllers;

/**
 *  获取索引对应的ViewController
 *  若index超出范围或对应控制器不可见，则返回nil
 *
 *  @param index 索引
 *
 *  @return UIViewController对象
 */
- (__kindof UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex;

/**
 *  切换到指定页面
 *
 *  @param pageIndex 页面索引
 *  @param animated  是否需要动画执行
 */
- (void)switchToPage:(NSUInteger)pageIndex animated:(BOOL)animated;

// 登录领福利
- (void)showPacket;
@end
