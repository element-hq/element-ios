//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum AuthenticationQRLoginLoadingViewModelResult {
    case cancel
}

// MARK: View

struct AuthenticationQRLoginLoadingViewState: BindableState {
    var loadingText: String?
}

enum AuthenticationQRLoginLoadingViewAction {
    case cancel
}
