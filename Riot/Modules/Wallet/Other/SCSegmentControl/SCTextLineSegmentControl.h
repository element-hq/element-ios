//
//  SCTextLineSegmentControl.h
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/19.
//

#import <UIKit/UIKit.h>
#import "SCSegmentControlProtocol.h"

typedef NS_ENUM(NSUInteger, SCTextLineIndicatorStyle) {
    SCTextLineIndicatorStyleRegular,            // 指示器宽度固定
    SCTextLineIndicatorStyleFollowContent,      // 指示器宽度与内容等宽
};

@interface SCTextLineSegmentControl : UIView <
SCSegmentControlProtocol
>

/// segment标题数组。自定义item时该属性无效
@property (nonatomic, strong) NSArray *titles;

/// 未被选中时标题的字体，默认15。自定义item时该属性无效
@property (nonatomic, strong) UIFont *normalItemTitleFont;

/// 未被选中时标题文字的颜色，默认黑色。自定义item时该属性无效
@property (nonatomic, strong) UIColor *normalItemTitleColor;

/// 选中时标题的字体，默认 bold 15。自定义item时该属性无效
@property (nonatomic, strong) UIFont *selectItemTitleFont;

/// 选中时标题的文字的颜色，默认橘黄色。自定义item时该属性无效
@property (nonatomic, strong) UIColor *selectItemTitleColor;

/// 是否隐藏指示器，默认为NO
@property (nonatomic, assign) BOOL hideIndicator;

/// 指示器的高度，默认为4
@property (nonatomic, assign) CGFloat indicatorHeight;

/// 指示器距离底部的间距，默认为0
@property (nonatomic, assign) CGFloat indicatorBottomSpace;

/// 指示器的宽度。指示器`indicatorStyle`为`SCTextLineIndicatorStyleRegular`时有效,默认为50
@property (nonatomic, assign) CGFloat indicatorRegularWidth;

/// 指示器宽度宽度展示规则
@property (nonatomic, assign) SCTextLineIndicatorStyle indicatorStyle;

/// 指示器圆角大小
@property (nonatomic, assign) CGFloat indicatorCorner;

/// 指示器背景颜色,默认orangeColor
@property (nonatomic, strong) UIColor *indicatorBackgroundColor;

/// 自定义指示器layer
@property (nonatomic, strong) CALayer *indicatorLayer;

/// 自定义指示器view
@property (nonatomic, strong) UIView *indicatorView;

/// 设置指示器内容为图片
@property (nonatomic, strong) UIImage *indicatorImage;

/// 指示器使用图片时，图片的缩放形式
@property (nonatomic, assign) UIViewContentMode indicatorImageViewMode;

/// 设置指示器的渐变
/// @param indicatorGradientColors 渐变颜色
/// @param startPoint 渐变起点
/// @param endPoint 渐变终点
/// @param locations 坐标点
- (void)setupIndicatorGradientWithColors:(NSArray *)indicatorGradientColors
                              startPoint:(CGPoint)startPoint
                                endPoint:(CGPoint)endPoint
                               locations:(NSArray<NSNumber *> *)locations;


@end
