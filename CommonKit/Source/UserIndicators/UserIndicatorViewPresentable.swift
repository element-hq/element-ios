// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A presenter associated with and called by a `UserIndicator`, and responsible for the underlying view shown on the screen.
public protocol UserIndicatorViewPresentable {
    /// Called when the `UserIndicator` is started (manually or by the `UserIndicatorQueue`)
    func present()
    /// Called when the `UserIndicator` is manually cancelled or completed
    func dismiss()
}

