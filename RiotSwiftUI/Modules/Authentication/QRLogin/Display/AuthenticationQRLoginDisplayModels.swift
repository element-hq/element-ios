//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

// MARK: - Coordinator

// MARK: View model

enum AuthenticationQRLoginDisplayViewModelResult {
    case cancel
}

// MARK: View

struct AuthenticationQRLoginDisplayViewState: BindableState {
    var qrImage: UIImage?
}

enum AuthenticationQRLoginDisplayViewAction {
    case cancel
}
