/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd
Copyright 2014 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 Bottom view for SectionHeaderView. Will be insetted respecting safe area insets.
 */
@interface LocalContactsSectionHeaderContainerView : UIView

/**
 Checkbox view. Both width and height will be used.
 */
@property (nonatomic, strong) UIView *checkboxView;

/**
 Checkbox label. Only height will be used.
 */
@property (nonatomic, strong) UILabel *checkboxLabel;

/**
 Mask view for the checkbox. No frame value will be used. Will be spanned to whole width & height.
 */
@property (nonatomic, strong) UIView *maskView;

@end
