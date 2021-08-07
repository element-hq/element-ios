//
//  VTMenuBar.h
//  VTMagicView
//
//  Created by tianzhuo on 15/1/6.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//  菜单栏

#import <UIKit/UIKit.h>
#import "VTEnumType.h"
NS_ASSUME_NONNULL_BEGIN

@class VTMenuBar;
@protocol VTMenuBarDatasource <NSObject>
/**
 *  根据index获取对应索引的menuItem
 *
 *  @param menuBar self
 *  @param index   需要加载的menuItem对应的索引
 *
 *  @return 当前索引对应的按钮
 */
- (nullable UIButton *)menuBar:(VTMenuBar *)menuBar menuItemAtIndex:(NSUInteger)itemIndex;

@end

@protocol VTMenuBarDelegate <NSObject>

@optional
/**
 *  导航菜单item被点击时触发
 *
 *  @param menuBar   self
 *  @param itemIndex 被选中的按钮索引
 */
- (void)menuBar:(VTMenuBar *)menuBar didSelectItemAtIndex:(NSUInteger)itemIndex;

/**
 *  根据itemIndex获取对应menuItem的宽度，若返回结果为0，内部将自动计算其宽度
 *
 *  @param magicView self
 *  @param itemIndex menuItem对应的索引
 *
 *  @return menuItem的宽度
 */
- (CGFloat)menuBar:(VTMenuBar *)menuBar itemWidthAtIndex:(NSUInteger)itemIndex;

/**
 *  根据itemIndex获取对应slider的宽度，若返回结果为0，内部将自动计算其宽度
 *
 *  @param magicView self
 *  @param itemIndex slider对应的索引
 *
 *  @return slider的宽度
 */
- (CGFloat)menuBar:(VTMenuBar *)menuBar sliderWidthAtIndex:(NSUInteger)itemIndex;

@end

@interface VTMenuBar : UIScrollView

/**
 *  数据源
 */
@property (nonatomic, weak, nullable) id <VTMenuBarDatasource> datasource;

/**
 *  代理
 */
@property (nonatomic, weak, nullable) id <VTMenuBarDelegate, UIScrollViewDelegate> delegate;

/**
 *  菜单名数组，字符串类型
 */
@property (nonatomic, strong, nullable) NSArray<__kindof NSString *> *menuTitles;

/**
 *  导航菜单布局样式
 */
@property (nonatomic, assign) VTLayoutStyle layoutStyle;

/**
 *  导航栏滑块样式，默认显示下划线
 */
@property (nonatomic, assign) VTSliderStyle sliderStyle;

/**
 *  当前选中item对应的索引
 */
@property (nonatomic, assign) NSUInteger currentIndex;

/**
 *  当前被选中的item
 */
@property (nonatomic, strong, readonly, nullable) UIButton *selectedItem;

/**
 *  导航菜单item的选中状态是否已被取消，默认NO
 */
@property (nonatomic, assign, getter=isDeselected) BOOL deselected;

/**
 *  是否需要跳过layout，菜单栏被滑动时该属性无效，强制布局
 */
@property (nonatomic, assign) BOOL needSkipLayout;

/**
 *  item之间的实际间距
 */
@property (nonatomic, assign) CGFloat acturalSpacing;

/**
 *  自定义item宽度，默认0，当设置改属性时，itemSpacing的设置无效
 *
 *  @warning 该属性在VTLayoutStyleDivide样式下无效
 */
@property (nonatomic, assign) CGFloat itemWidth;

/**
 *  两个导航菜单item文本之间的间距，默认是25，其优先级低于itemWidth
 *  如果菜单item包含图片，则实际间距可能会更小
 *
 *  @warning 该属性在VTLayoutStyleDivide样式下无效
 */
@property (nonatomic, assign) CGFloat itemSpacing;

/**
 *  menuItem被选中时文本的放大倍数，默认1.0
 *  可根据需要设置合适的数值，通常不宜超过1.5
 */
@property (nonatomic, assign) CGFloat itemScale;

/**
 *  导航菜单的inset，对leftHeaderView和rightHeaderView无效
 */
@property (nonatomic, assign) UIEdgeInsets menuInset;

/**
 *  气泡相对menuItem文本的edgeInsets，默认(2, 5, 2, 5)
 */
@property (nonatomic, assign) UIEdgeInsets bubbleInset;

/**
 *  顶部导航栏滑块高度，默认2
 *
 *  @warning 非VTSliderStyleDefault样式，该属性无效
 */
@property (nonatomic, assign) CGFloat sliderHeight;

/**
 *  顶部导航栏滑块宽度，VTSliderStyleDefault样式下滑块宽度默认与item宽度一致
 *
 *  @warning 非VTSliderStyleDefault样式，该属性无效
 */
@property (nonatomic, assign) CGFloat sliderWidth;

/**
 *  滑块宽度延长量，0表示滑块宽度与文本宽度一致，该属性优先级低于sliderWidth
 *
 *  @warning 非VTSliderStyleDefault样式或sliderWidth有效时，该属性无效
 */
@property (nonatomic, assign) CGFloat sliderExtension;

/**
 *  顶部导航栏滑块相对导航底部的偏移量，默认0，上偏为负
 *
 *  @warning 非VTSliderStyleDefault样式，该属性无效
 */
@property (nonatomic, assign) CGFloat sliderOffset;

#pragma mark - public methods
/**
 *  刷新数据
 */
- (void)reloadData;

/**
 *  重置所有item的frame
 */
- (void)resetItemFrames;

/**
 *  更新被选中按钮，并根据需要决定是否调整menuItem文本的大小
 *
 *  @param transformScale 是否改变scale
 */
- (void)updateSelectedItem:(BOOL)transformScale;

/**
 *  取消导航菜单item的选中状态
 */
- (void)deselectMenuItem;

/**
 *  恢复导航菜单item的选中状态
 */
- (void)reselectMenuItem;

/**
 *  根据索引获取对应item对应的frame
 *
 *  @param index 索引
 *
 *  @return 当前索引对应item的frame
 */
- (CGRect)itemFrameAtIndex:(NSUInteger)index;

/**
 *  根据索引获取slider当前的frame
 *
 *  @param index 索引
 *
 *  @return 当前索引对应的slider的frame
 */
- (CGRect)sliderFrameAtIndex:(NSUInteger)index;

/**
 *  根据索引获取当前页面显示的item，不在窗口上显示的则为nil
 *
 *  @param index 索引
 *
 *  @return 当前索引对应的item
 */
- (nullable UIButton *)itemAtIndex:(NSUInteger)index;

/**
 *  根据索引生成对应的item，若对应item已经存在，则直接返回
 *
 *  @param index 索引
 *
 *  @return 当前索引对应的item
 */
- (nullable UIButton *)createItemAtIndex:(NSUInteger)index;

/**
 *  根据重用标识查询可重用的category item
 *
 *  @param identifier 重用标识
 *
 *  @return 缓存池中取出的category item
 */
- (nullable __kindof UIButton *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
