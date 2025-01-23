// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#ifndef UserIndicatorCancel_h
#define UserIndicatorCancel_h

/**
 Callback function to cancel a `UserIndicator` without needing a direct reference to the object
 
 Note: the function is defined in Objective-C (instead of Swift) to be accessible by both languages.
 */
typedef void (^UserIndicatorCancel)(void);

#endif /* UserIndicatorCancel_h */
