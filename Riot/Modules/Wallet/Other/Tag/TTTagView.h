//
//  TTTagView.h
//  QQtagView
//
//  Created by 王家强 on 2020/6/19.
//  Copyright © 2020 ZhangQun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - :::::::::::::: TTTagItem ::::::::::::::
@interface TTTagItem : UIButton

@property (strong, nonatomic) UIColor *normalBackgroundColor;

@property (strong, nonatomic) UIColor *selectedBackgroundColor;

@property (strong, nonatomic) UIColor *normalBorderColor;

@property (strong, nonatomic) UIColor *selectedBorderColor;

@property(nonatomic,strong) id model;

@end


#pragma mark - :::::::::::::: TTTagView ::::::::::::::
@interface TTTagView : UIView

#pragma mark - :::::::::::::: 标签数据 ::::::::::::::


/**
  数据来源源
  支持的数据类型可以是string类型的数组 如 @[@"测试文本",@"文本1",@"文本2",@"文本"];
  也可以是字典类型的数组  @[@{@"code":@"1",@"name":@"测试文本"},@{@"code":@"1",@"name":@"测试文本"}];
 */
@property (nonatomic,strong) NSArray *tagsArray;

/**
 默认选中的数据
 */
@property (nonatomic,retain) NSArray *defaultSelectTags;

/**
 选中的数据
*/
@property (nonatomic,strong) NSArray *selectTags;

#pragma mark - :::::::::::::: 标签布局相关属性 ::::::::::::::
// 显示的行数，默认不限制，如限制，需指定具体的数字，多出的将分页显示
@property (nonatomic) NSInteger numberOfLines;
// 行间距, 默认为10
@property (nonatomic) CGFloat lineSpacing;
// 元素之间的间距，默认为6
@property (nonatomic) CGFloat itemSpacing;

#pragma mark - :::::::::::::: 标签样式属性 ::::::::::::::
// 圆角
@property(nonatomic,assign) CGFloat cornerRadius;

// 默认标签文字颜色
@property (strong, nonatomic) UIColor *tagTextColor;
// 选中标签文字颜色
@property (strong, nonatomic) UIColor *tagSelectedTextColor;
// 默认标签背景颜色
@property (strong, nonatomic) UIColor *tagBackgroundColor;
// 选中标签背景颜色
@property (strong, nonatomic) UIColor *tagSelectedBackgroundColor;
// 默认标签边线颜色
@property (strong, nonatomic) UIColor *tagBorderColor;
// 选中标签边线颜色
@property (strong, nonatomic) UIColor *tagSelectedBorderColor;
// 默认标签字体
@property (strong, nonatomic) UIFont *tagFont;
// 选中标签字体
@property (strong, nonatomic) UIFont *tagSelectedFont;
// pageControl
@property (strong, nonatomic) UIImage *pageIndicatorImage;
@property (strong, nonatomic) UIImage *currentPageIndicatorImage;
@property (strong, nonatomic) UIColor *pageIndicatorTintColor;
@property (strong, nonatomic) UIColor *currentPageIndicatorTintColor;
@property (copy , nonatomic) void (^selectItemBlock)(UIButton *sender);
#pragma mark - :::::::::::::: 标签选中控制 ::::::::::::::
// 默认是否选中状态
@property (nonatomic) BOOL selected;
// 是否允许选中, default is YES 当为NO是，标签不可选择
@property (nonatomic) BOOL allowsSelection;
// 是否允许多选, default is NO
@property (nonatomic) BOOL allowsMultipleSelection;

// 是否分页 default is YES （这里有个特例，当单行显示的时候，pageControl不显示）
@property (nonatomic) BOOL pageControlEnabled;

#pragma mark - :::::::::::::: 标签动态增减 ::::::::::::::
- (void)addTag:(id)model;
- (void)removeTag:(id)model;

@end

NS_ASSUME_NONNULL_END
