//
//  UIView+Category_lib.h
//  UniversalApp
//
//  Created by 廖燊 on 2021/5/29.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Category_lib)
#pragma mark - 手势
/**
 *  添加单击手势
 */
- (void)mm_addTapGestureWithTarget:(id)target action:(SEL)action;

/**
 *  添加滑动手势
 */
- (void)mm_addPanGestureWithTarget:(id)target action:(SEL)action;

- (void)addTapAction:(void(^)(UITapGestureRecognizer *sender))handler;
- (void)addLongPressAction:(void (^)(UILongPressGestureRecognizer *))handler;

@end

NS_ASSUME_NONNULL_END
