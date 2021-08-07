//
//  SCSegmentControlProtocol.h
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import "SCSegmentControlDataSource.h"
#import "SCSegmentControlDelegate.h"

@protocol SCSegmentControlProtocol <NSObject>

/// 指定被点击的item是否滚动至控件中间位置，默认为YES
@property (nonatomic, assign) BOOL scrollToCenter;

/// 指定内容内边距，默认均为0
@property (nonatomic, assign) UIEdgeInsets contentInset;

/// 当前选中的item的下标
@property (nonatomic, assign, readonly) NSInteger currentIndex;

/// SCSegmentControl的一些回调
@property (nonatomic, weak) id<SCSegmentControlDelegate> delegate;

/// SCSegmentControl的数据源
@property (nonatomic, weak) id<SCSegmentControlDataSource> dataSource;

@optional

/// 注册nib文件
/// @param nib nib
/// @param identifier 重用标识
- (void)registerNib:(UINib *)nib forSegmentControlItemWithReuseIdentifier:(NSString *)identifier;

/// 注册class
/// @param cellClass cellClass
/// @param identifier 重用标识
- (void)registerClass:(Class)cellClass forSegmentControlItemWithReuseIdentifier:(NSString *)identifier;

/// 通过重用标识获取cell
/// @param identifier 重用标识
/// @param index 下标
- (UICollectionViewCell *)dequeueReusableSegmentControlItemWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

/// 处理数据源（设置完属性，实现相关代理后，需要调用该方法）
- (void)processDataSource;

/// 刷新
- (void)reloadData;

/// 指定item被选中
/// @param selectedIndex item的下标
- (void)setupSelectedIndex:(NSInteger)selectedIndex;

@end


