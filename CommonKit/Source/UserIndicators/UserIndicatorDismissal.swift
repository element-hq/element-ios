// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Different ways in which a `UserIndicator` can be dismissed
public enum UserIndicatorDismissal {
    /// The `UserIndicator` will not manage the dismissal, but will expect the calling client to do so manually
    case manual
    /// The `UserIndicator` will be automatically dismissed after `TimeInterval`
    case timeout(TimeInterval)
}
