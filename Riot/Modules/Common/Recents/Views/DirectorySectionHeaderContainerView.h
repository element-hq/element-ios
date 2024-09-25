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
@interface DirectorySectionHeaderContainerView : UIView

/**
 Network label. Both width and height will be used.
 */
@property (nonatomic, strong) UILabel *networkLabel;

/**
 Directory server label. Only height will be used.
 */
@property (nonatomic, strong) UIView *directoryServerLabel;

/**
 Disclosure view. Both width and height will be used.
 */
@property (nonatomic, strong) UIView *disclosureView;

@end
