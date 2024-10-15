/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#pragma mark - Imports

@import Foundation;
@import UIKit;

#pragma mark - Types

typedef void (^MXKBarButtonItemAction)(void);

#pragma mark - Interface

/**
 `MXKBarButtonItem` is a subclass of UIBarButtonItem allowing to use convenient action block instead of action selector.
 */
@interface MXKBarButtonItem : UIBarButtonItem

#pragma mark - Instance Methods

- (instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action;
- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action;

@end
