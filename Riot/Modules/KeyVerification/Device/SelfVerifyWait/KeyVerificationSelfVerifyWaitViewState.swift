// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

enum SecretsRecoveryAvailability {
    case notAvailable
    case available(_ mode: SecretsRecoveryMode)
}

struct KeyVerificationSelfVerifyWaitViewData {
    let isNewSignIn: Bool
    let secretsRecoveryAvailability: SecretsRecoveryAvailability
}

/// KeyVerificationSelfVerifyWaitViewController view state
enum KeyVerificationSelfVerifyWaitViewState {
    case loading
    case secretsRecoveryCheckingAvailability(_ text: String?)
    case loaded(_ viewData: KeyVerificationSelfVerifyWaitViewData)
    case cancelled(MXTransactionCancelCode)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
