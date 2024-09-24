// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
