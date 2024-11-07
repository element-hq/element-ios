/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 MXKMessageTextView is a UITextView subclass with link detection without text selection.
 */
@interface MXKMessageTextView : UITextView

// The last hit test location received by the view.
@property (nonatomic, readonly) CGPoint lastHitTestLocation;


/// Register a view that has been added as a pill to this text view.
/// This is needed in order to flush pills that are not always removed properly by the system.
/// All registered views will be manually removed from hierarchy on attributedText or text updates.
///
/// @param pillView pill view to register
- (void)registerPillView:(UIView *)pillView API_AVAILABLE(ios(15));

@end

NS_ASSUME_NONNULL_END
