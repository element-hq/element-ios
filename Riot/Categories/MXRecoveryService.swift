/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension MXRecoveryService {
    
    var vc_availability: SecretsRecoveryAvailability {
        guard self.hasRecovery() else {
            return .notAvailable
        }
        let secretsRecoveryMode: SecretsRecoveryMode = self.usePassphrase() ? .passphraseOrKey : .onlyKey
        return .available(secretsRecoveryMode)
    }
}
