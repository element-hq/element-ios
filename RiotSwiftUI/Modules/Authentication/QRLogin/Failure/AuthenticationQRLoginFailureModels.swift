//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum AuthenticationQRLoginFailureViewModelResult {
    case retry
    case cancel
}

// MARK: View

struct AuthenticationQRLoginFailureViewState: BindableState {
    var retryButtonVisible: Bool
    var failureText: String?
}

enum AuthenticationQRLoginFailureViewAction {
    case retry
    case cancel
}
