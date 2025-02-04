// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <MatrixSDK/MatrixSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXSession (MatrixKit)

/// Flag to indicate whether the session is in a suitable state to show some activity indicators on UI.
@property (nonatomic, readonly) BOOL shouldShowActivityIndicator;

@end

NS_ASSUME_NONNULL_END
