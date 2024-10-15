/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (MatrixKit)

/**
 The main navigation controller if the view controller is embedded inside a split view controller.
 */
@property (nullable, nonatomic, readonly) UINavigationController *mxk_mainNavigationController;

@end

NS_ASSUME_NONNULL_END
