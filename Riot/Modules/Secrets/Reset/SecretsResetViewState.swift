// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsResetViewController view state
enum SecretsResetViewState {
    case resetting
    case resetDone
    case resetCancelled
    case error(Error)
}
