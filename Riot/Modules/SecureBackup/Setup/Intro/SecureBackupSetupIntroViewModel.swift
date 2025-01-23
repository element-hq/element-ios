// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final class SecureBackupSetupIntroViewModel: SecureBackupSetupIntroViewModelType {
    
    // MARK: - Properties

    // TODO: Make these properties private
    let keyBackup: MXKeyBackup?
    let checkKeyBackup: Bool
    let homeserverEncryptionConfiguration: HomeserverEncryptionConfiguration
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup?, checkKeyBackup: Bool, homeserverEncryptionConfiguration: HomeserverEncryptionConfiguration) {
        self.keyBackup = keyBackup
        self.checkKeyBackup = checkKeyBackup
        self.homeserverEncryptionConfiguration = homeserverEncryptionConfiguration
    }
}
