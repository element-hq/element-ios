// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

/// Configurable expose settings app and its entensions must use.
@objc protocol Configurable {
    // MARK: - Global settings
    func setupSettings()
    
    // MARK: - Per matrix session settings
    func setupSettings(for matrixSession: MXSession)
}
