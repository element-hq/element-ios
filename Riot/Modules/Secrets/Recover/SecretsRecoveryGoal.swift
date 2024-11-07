/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

enum SecretsRecoveryGoal {
    case `default`
    case keyBackup
    /// Unlock the secure backup (4S) to get the private key and execute a closure during the flow
    case unlockSecureBackup ((_ privateKey: Data, _ completion: @escaping (Result<Void, Error>) -> Void) -> Void)
    case verifyDevice
    case restoreSecureBackup
}

@objc
enum SecretsRecoveryGoalBridge: Int {
    case `default`
    case keyBackup
    case verifyDevice
    case restoreSecureBackup
    
    var goal: SecretsRecoveryGoal {
        switch self {
        case .default: return .default
        case .keyBackup: return .keyBackup
        case .verifyDevice: return .verifyDevice
        case .restoreSecureBackup: return .restoreSecureBackup
        }
    }
}
