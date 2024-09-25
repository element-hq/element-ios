/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 Define a `UIAlertController` category at MatrixKit level to handle accessibility identifiers.
 */
@interface UIAlertController (MatrixKit)

/**
 Apply an accessibility on the alert view and its items (actions and text fields).
 
 @param accessibilityIdentifier the identifier.
 */
- (void)mxk_setAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

@end
