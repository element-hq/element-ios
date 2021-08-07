//
//  VTMagicView.h
//  VTMagicView
//
//  Created by tianzhuo on 14-11-11.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VTMagicProtocol.h"
#import "VTEnumType.h"
#import "VTContentView.h"
#import "VTMenuBar.h"

@class VTMagicView;

/****************************************data source****************************************/
@protocol VTMagicViewDataSource <NSObject>
/**
 *  获取所有分类名，数组中存放字符串类型对象
 *
 *  @param magicView self
 *
 *  @return header数组
 */
- (NSArray<__kindof NSString *> *)menuTitlesForMagicView:(VTMagicView *)magicView;

/**
 *  根据index获取对应索引的menuItem
 *
 *  @param magicView self
 *  @param index     当前索引
 *
 *  @return 当前索引对应的按钮
 */
- (UIButton *)magicView:(VTMagicView *)magicView menuItemAtIndex:(NSUInteger)itemIndex;

/**
 *  当前索引对应的控制器
 *
 *  @param magicView self
 *  @param index     当前索引
 *
 *  @return 控制器
 */
- (UIViewController *)magicView:(VTMagicView *)magicView viewControllerAtPage:(NSUInteger)pageIndex;

@end

/****************************************delegate****************************************/
@protocol VTMagicViewDelegate <NSObject>

@optional
/**
 *  视图控制器显示到当前屏幕上时触发
 *
 *  @param magicView      self
 *  @param viewController 当前页面展示的控制器
 *  @param index          当前控控制器对应的索引
 */
- (void)magicView:(VTMagicView *)magicView viewWillAppear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex;

/**
 *  视图控制器显示到当前屏幕上时触发
 *
 *  @param magicView      self
 *  @param viewController 当前页面展示的控制器
 *  @param index          当前控控制器对应的索引
 */
- (void)magicView:(VTMagicView *)magicView viewDidAppear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex;

/**
 *  视图控制器从屏幕上消失时触发
 *
 *  @param magicView      self
 *  @param viewController 消失的视图控制器
 *  @param index          当前控制器对应的索引
 */
- (void)magicView:(VTMagicView *)magicView viewDidDisappear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex;

/**
 *  选中导航菜单item时触发
 *
 *  @param magicView self
 *  @param itemIndex 分类索引
 */
- (void)magicView:(VTMagicView *)magicView didSelectItemAtIndex:(NSUInteger)itemIndex;

/**
 *  根据itemIndex获取对应menuItem的宽度，若返回结果为0，内部将自动计算其宽度
 *  通常情况下只需设置itemSpacing或itemWidth即可
 *
 *  @param magicView self
 *  @param itemIndex menuItem对应的索引
 *
 *  @return menuItem的宽度
 */
- (CGFloat)magicView:(VTMagicView *)magicView itemWidthAtIndex:(NSUInteger)itemIndex;

/**
 *  根据itemIndex获取对应slider的宽度，若返回结果为0，内部将自动计算其宽度
 *  通常情况下只需设置sliderWidth、sliderExtension或bubbleInset即可
 *
 *  @param magicView self
 *  @param itemIndex slider对应的索引
 *
 *  @return slider的宽度
 */
- (CGFloat)magicView:(VTMagicView *)magicView sliderWidthAtIndex:(NSUInteger)itemIndex;

@end

@interface VTMagicView : UIView

#pragma mark - basic configurations
/****************************************basic configurations****************************************/

/**
 *  数据源
 */
@property (nonatomic, weak) id<VTMagicViewDataSource> dataSource;

/**
 *  代理
 *  若delegate为UIViewController并且实现了VTMagicProtocol协议，
 *  则主控制器(mainViewController)默认与其相同
 */
@property (nonatomic, weak) id<VTMagicViewDelegate> delegate;

/**
 *  主控制器，若delegate遵循协议VTMagicProtocol，则默认与其相同
 *
 *  @warning 若继承自或直接实例化VTMagicController，则不需要设置该属性
 */
@property (nonatomic, weak) UIViewController<VTMagicProtocol> *magicController;

/**
 *  切换样式，默认是VTSwitchStyleDefault
 */
@property (nonatomic, assign) VTSwitchStyle switchStyle;

/**
 *  导航菜单的布局样式
 */
@property (nonatomic, assign) VTLayoutStyle layoutStyle;

/**
 *  导航栏滑块样式，默认显示下划线
 */
@property (nonatomic, assign) VTSliderStyle sliderStyle;

/**
 *  导航菜单item的预览数，默认为1
 */
@property (nonatomic, assign) NSUInteger previewItems;

#pragma mark - subviews
/****************************************subviews****************************************/

@property (readonly) VTContentView *contentView; // 容器视图

/**
 *  最顶部的头部组件，默认隐藏
 *  若需显示请通过属性headerHidden设置
 */
@property (nonatomic, strong, readonly) UIView *headerView;

/**
 *  顶部导航视图
 */
@property (nonatomic, strong, readonly) UIView *navigationView;

/**
 *  顶部导航栏左侧视图项
 */
@property (nonatomic, strong) UIView *leftNavigatoinItem;

/**
 *  顶部导航栏右侧视图项
 */
@property (nonatomic, strong) UIView *rightNavigatoinItem;

/**
 *  屏幕上可见的控制器
 */
@property (nonatomic, strong, readonly) NSArray<__kindof UIViewController *> *viewControllers;

#pragma mark - bool configurations
/****************************************bool configurations****************************************/

/**
 *  是否允许页面左右滑动，默认YES
 */
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;

/**
 *  是否允许导航菜单左右滑动，默认YES
 */
@property (nonatomic, assign, getter=isMenuScrollEnabled) BOOL menuScrollEnabled;

/**
 *  是否允许切换，包括左右滑动和点击切换，默认YES
 *  若禁止，则所有切换事件全部无响应，非特殊情况不应修改本属性
 */
@property (nonatomic, assign, getter=isSwitchEnabled) BOOL switchEnabled;

/**
 *  点击导航菜单切换页面时是否需要动画，默认YES
 */
@property (nonatomic, assign, getter=isSwitchAnimated) BOOL switchAnimated;

/**
 *  隐藏滑块
 */
@property (nonatomic, assign, getter=isSliderHidden) BOOL sliderHidden;

/**
 *  隐藏导航分割线
 */
@property (nonatomic, assign, getter=isSeparatorHidden) BOOL separatorHidden;

/**
 *  导航栏item的选中状态是否已被取消，默认NO
 */
@property (nonatomic, assign, readonly, getter=isDeselected) BOOL deselected;

/**
 *  顶部导航栏是否紧贴系统状态栏，即是否需要为状态栏留出20个点的区域，默认NO
 */
@property (nonatomic, assign, getter=isAgainstStatusBar) BOOL againstStatusBar;

/**
 *  是否隐藏头部组件，默认YES
 */
@property (nonatomic, assign, getter=isHeaderHidden) BOOL headerHidden;

/**
    是否隐藏菜单右侧阴影
 */
@property (nonatomic, assign) BOOL shieldBarShadow;
/**
 *  显示或隐藏头部组件
 *
 *  @param headerHidden 是否隐藏
 *  @param duration     动画时长
 */
- (void)setHeaderHidden:(BOOL)headerHidden duration:(CGFloat)duration;

/**
 *  页面滑到两侧边缘时是否需要反弹效果，默认NO
 */
@property (nonatomic, assign) BOOL bounces;

/**
 *  底部是否需要扩展一个tabbar的高度，设置毛玻璃效果时或许有用，默认NO
 */
@property (nonatomic, assign) BOOL needExtendedBottom;

#pragma mark - color & size configurations
/**************************************color & size**************************************/

/**
 *  导航菜单栏的inset，对leftNavigatoinItem和rightNavigatoinItem无效
 */
@property (nonatomic, assign) UIEdgeInsets navigationInset;

/**
 *  顶部导航栏背景色
 */
@property (nonatomic, strong) UIColor *navigationColor;

/**
 *  顶部导航条的高度，默认是44
 */
@property (nonatomic, assign) CGFloat navigationHeight;

/**
 *  顶部导航栏底部分割线颜色
 */
@property (nonatomic, strong) UIColor *separatorColor;

/**
 *  导航栏分割线高度，默认0.5个点
 */
@property (nonatomic, assign) CGFloat separatorHeight;

/**
 *  顶部导航栏滑块颜色
 */
@property (nonatomic, strong) UIColor *sliderColor;

/**
 *  顶部导航栏滑块高度，默认2
 *
 *  @warning 非VTSliderStyleDefault样式，该属性无效
 */
@property (nonatomic, assign) CGFloat sliderHeight;

/**
 *  顶部导航栏滑块宽度，VTSliderStyleDefault样式下默认与item宽度一致
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

/**
 *  气泡相对menuItem文本的edgeInsets，默认(2, 5, 2, 5)
 *
 *  @warning 该属性用于VTSliderStyleBubble样式下
 */
@property (nonatomic, assign) UIEdgeInsets bubbleInset;

/**
 *  滑块的圆角半径，默认10
 *
 *  @warning 该属性用于VTSliderStyleBubble样式下
 */
@property (nonatomic, assign) CGFloat bubbleRadius;

/**
 *  头部组件的高度默认64
 */
@property (nonatomic, assign) CGFloat headerHeight;

/**
 *  两个导航菜单item文本之间的间距，默认是25
 *  如果分类item包含图片，则实际间距可能会更小
 *
 *  @warning 该属性仅VTLayoutStyleDefault和VTLayoutStyleCenter样式下有效！
 */
@property (nonatomic, assign) CGFloat itemSpacing;

/**
 *  menuItem被选中时文本的放大倍数，默认1.0
 *  可根据需要设置合适的数值，通常不宜超过1.5
 */
@property (nonatomic, assign) CGFloat itemScale;

/**
 *  自定义item宽度
 *
 *  @warning 仅VTLayoutStyleCustom样式下有效
 */
@property (nonatomic, assign) CGFloat itemWidth;

#pragma mark - other properties
/**************************************other properties**************************************/

/**
 *  页面切换事件，用于行为统计
 */
@property (nonatomic, assign, readonly) VTSwitchEvent switchEvent;

#pragma mark - public method
/**************************************public method**************************************/

/**
 *  重新加载所有数据
 */
- (void)reloadData;

/**
 *  重新加载所有数据，同时定位到指定页面，若page越界，则自动修正为0
 *
 *  @param page 被定位的页面
 */
- (void)reloadDataToPage:(NSUInteger)page;

/**
 *  查询可重用menuItem
 *
 *  @param identifier 重用标识
 *
 *  @return 可重用的menuItem
 */
- (__kindof UIButton *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

/**
 *  根据缓存标识获取可重用的UIViewController
 *
 *  @param identifier 缓存重用标识
 *
 *  @return 可重用的UIViewController
 */
- (__kindof UIViewController *)dequeueReusablePageWithIdentifier:(NSString *)identifier;

/**
 *  获取索引对应的ViewController
 *  若index超出范围或对应控制器不可见，则返回nil
 *
 *  @param pageIndex 索引
 *
 *  @return UIViewController对象
 */
- (__kindof UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex;

/**
 *  根据索引获取当前页面显示的menuItem，不在窗口上显示的则为nil
 *
 *  @param index 索引
 *
 *  @return 当前索引对应的menuItem
 */
- (__kindof UIButton *)menuItemAtIndex:(NSUInteger)index;

/**
 *  切换到指定页面
 *
 *  @param pageIndex 页面索引
 *  @param animated  是否需要动画执行
 */
- (void)switchToPage:(NSUInteger)pageIndex animated:(BOOL)animated;
- (void)switchWithoutAnimation:(NSUInteger)pageIndex;
- (void)switchAnimation:(NSUInteger)pageIndex;
/**
 *  处理UIPanGestureRecognizer手势，用于解决页面内嵌时无法响应手势问题
 *
 *  @param recognizer 手势
 */
- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer;

/**
 *  更新菜单标题，但不重新加载页面
 *  仅限于分类顺序和页数不改变的情况下
 *  一般情况下建议使用reloadData方法
 */
- (void)updateMenuTitles;

/**
 *  取消菜单item的选中状态，可通过属性deselected获取当前状态
 *  取消选中后须调用方法reSelectMenuItem以恢复
 */
- (void)deselectMenuItem;

/**
 *  恢复菜单menuItem的选中状态
 */
- (void)reselectMenuItem;

- (UIButton *)cacheBar;

- (void)updateBarShadow;
@end
