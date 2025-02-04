// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Methods to use to setup secure backup (SSSS).
@objc enum VectorWellKnownBackupSetupMethod: Int, CaseIterable {
    case passphrase = 0
    case key

    private enum Constants {
        static let setupMethodPassphrase: String = "passphrase"
        static let setupMethodKey: String = "key"
    }

    init?(key: String) {
        switch key {
        case Constants.setupMethodPassphrase:
            self = .passphrase
        case Constants.setupMethodKey:
            self = .key
        default:
            return nil
        }
    }
}
