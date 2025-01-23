// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Protocol describing the view model used by `SecureBackupSetupIntroViewController`
protocol SecureBackupSetupIntroViewModelType {
            
    // TODO: Hide these properties from interface and use same behavior as other view models
    var keyBackup: MXKeyBackup? { get }
    var checkKeyBackup: Bool { get }
    var homeserverEncryptionConfiguration: HomeserverEncryptionConfiguration { get }
}
