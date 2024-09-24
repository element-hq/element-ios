// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsSetupRecoveryPassphraseViewController view actions exposed to view model
enum SecretsSetupRecoveryPassphraseViewAction {
    case loadData
    case updatePassphrase(_ passphrase: String?)
    case validate
    case cancel
}
