/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 The Matrix iOS Kit version.
 */
FOUNDATION_EXPORT NSString *const MatrixKitVersion;

/**
 Posted when an error is observed at Matrix Kit level.
 This notification may be used to inform user by showing the error as an alert.
 The notification object is the NSError instance.
 
 The passed userInfo dictionary may contain:
 - `kMXKErrorUserIdKey` the matrix identifier of the account concerned by this error.
 */
FOUNDATION_EXPORT NSString *const kMXKErrorNotification;

/**
 The key in notification userInfo dictionary representating the account userId.
 */
FOUNDATION_EXPORT NSString *const kMXKErrorUserIdKey;
