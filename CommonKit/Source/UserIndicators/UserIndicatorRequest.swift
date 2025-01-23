// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A request used to create an underlying `UserIndicator`, allowing clients to only specify the visual aspects of an indicator.
public struct UserIndicatorRequest {
    internal let presenter: UserIndicatorViewPresentable
    internal let dismissal: UserIndicatorDismissal
    
    public init(presenter: UserIndicatorViewPresentable, dismissal: UserIndicatorDismissal) {
        self.presenter = presenter
        self.dismissal = dismissal
    }
}
