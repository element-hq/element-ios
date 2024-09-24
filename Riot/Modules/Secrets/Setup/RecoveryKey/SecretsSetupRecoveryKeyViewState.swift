// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsSetupRecoveryKeyViewController view state
enum SecretsSetupRecoveryKeyViewState {
    case loaded(_ passphraseOnly: Bool)
    case loading
    case recoveryCreated(_ recoveryKey: String)
    case error(Error)
}
