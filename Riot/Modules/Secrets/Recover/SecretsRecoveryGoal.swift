/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
