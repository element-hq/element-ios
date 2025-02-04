// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `HomeserverEncryptionConfiguration` gives encryption configuration used by homeserver
@objcMembers
final class HomeserverEncryptionConfiguration: NSObject {
    let isE2EEByDefaultEnabled: Bool
    let isSecureBackupRequired: Bool
    let secureBackupSetupMethods: [VectorWellKnownBackupSetupMethod]
    let outboundKeysPreSharingMode: MXKKeyPreSharingStrategy
    let deviceDehydrationEnabled: Bool

    init(isE2EEByDefaultEnabled: Bool,
         isSecureBackupRequired: Bool,
         secureBackupSetupMethods: [VectorWellKnownBackupSetupMethod],
         outboundKeysPreSharingMode: MXKKeyPreSharingStrategy,
         deviceDehydrationEnabled: Bool) {
        self.isE2EEByDefaultEnabled = isE2EEByDefaultEnabled
        self.isSecureBackupRequired = isSecureBackupRequired
        self.outboundKeysPreSharingMode = outboundKeysPreSharingMode
        self.secureBackupSetupMethods = secureBackupSetupMethods
        self.deviceDehydrationEnabled = deviceDehydrationEnabled

        super.init()
    }
}
