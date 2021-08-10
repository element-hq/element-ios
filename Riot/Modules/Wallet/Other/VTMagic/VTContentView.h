//
//  VTContentView.h
//  VTMagicView
//
//  Created by tianzhuo on 14/12/29.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//  内容页

#import <UIKit/UIKit.h>
#import "VTCommon.h"

@class VTContentView;
/**
 *  数据源协议
 */
@protocol VTContentViewDataSource <NSObject>
/**
 *  根据索引获取对应的控制器
 *
 *  @param content self
 *  @param index   索引
 *
 *  @return 当前索引对应的控制器
 */
- (UIViewController *)contentView:(VTContentView *)contentView viewControllerAtPage:(NSUInteger)pageIndex;

@end

@interface VTContentView : UIScrollView

/**
 *  一次加载所有的控制器,默认是NO
 */
@property (nonatomic ,assign) BOOL isNeedDisplayWithFrame;
/**
 *  数据源
 */
@property (nonatomic, weak) id <VTContentViewDataSource> dataSource;

/**
 *  页面数量
 */
@property (nonatomic, assign) NSUInteger pageCount;

/**
 *  当前页面索引
 */
@property (nonatomic, assign) NSUInteger currentPage;

/**
 *  屏幕上可见的控制器
 */
@property (nonatomic, strong, readonly) NSArray *visibleList;

#pragma mark - public methods
/**
 *  刷新数据
 */
- (void)reloadData;

/**
 *  重置所有内容页的frame
 */
- (void)resetPageFrames;

/**
 *  获取索引对应的ViewController
 *  若index超出范围或对应控制器不可见，则返回nil
 *
 *  @param index 索引
 *
 *  @return UIViewController对象
 */
- (UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex;

/**
 *  根据索引生成对应的ViewController，若对应ViewController已经存在，则直接返回
 *
 *  @param index 索引
 *
 *  @return UIViewController对象
 */
- (UIViewController *)creatViewControllerAtPage:(NSUInteger)pageIndex;

/**
 *  获取索引对应的ViewController，当ViewController为nil时，根据autoCreate的值决定是否创建
 *
 *  @param index      索引
 *  @param autoCreate 是否需要自动创建新的ViewController
 *
 *  @return UIViewController对象
 */
- (UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex autoCreate:(BOOL)autoCreate;

/**
 *  根据缓存标识查询可重用的UIViewController
 *
 *  @param identifier 缓存重用标识
 *
 *  @return 可重用的视图控制器
 */
- (__kindof UIViewController *)dequeueReusablePageWithIdentifier:(NSString *)identifier;

@end
