// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SecretsSetupRecoveryKeyViewController view actions exposed to view model
enum SecretsSetupRecoveryKeyViewAction {
    case loadData
    case done
    case errorAlertOk
    case cancel
}
