// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsResetViewController view actions exposed to view model
enum SecretsResetViewAction {
    case loadData
    case reset
    case authenticationCancelled
    case authenticationInfoEntered(_ authInfo: [String: Any])
    case cancel
}
