// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

enum SecretsSetupRecoveryPassphraseViewDataMode {
    case newPassphrase(strength: PasswordStrength)
    case confimPassphrase
}

struct SecretsSetupRecoveryPassphraseViewData {
    let mode: SecretsSetupRecoveryPassphraseViewDataMode
    let isFormValid: Bool
}

/// SecretsSetupRecoveryPassphraseViewController view state
enum SecretsSetupRecoveryPassphraseViewState {
    case loaded(_ viewData: SecretsSetupRecoveryPassphraseViewData)
    case formUpdated(_ viewData: SecretsSetupRecoveryPassphraseViewData)
    case error(Error)
}
