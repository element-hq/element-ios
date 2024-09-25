/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CircleButton : UIButton

/**
 Background color that is used for highlighted state
 
 By default the same as borderColor
 */
@property (nonatomic) UIColor *highlightBackgroundColor;

/**
 Background color that is used for normal state
 
 By default white
 */
@property (nonatomic) UIColor *defaultBackgroundColor;

/**
 Tint color that is used for highlighted state
 
 By default is white
 */
@property (nonatomic) UIColor *highlightTintColor;

/**
 Tint color that is used for normal state
 
 By default is the same as borderColor
 */
@property (nonatomic) UIColor *defaultTintColor;

- (instancetype)initWithImage:(UIImage *)image borderColor:(UIColor *)borderColor;

@end

NS_ASSUME_NONNULL_END
