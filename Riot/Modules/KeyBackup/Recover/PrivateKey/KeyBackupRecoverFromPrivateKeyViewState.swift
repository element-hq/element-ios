// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyBackupRecoverFromPrivateKeyViewController view state
enum KeyBackupRecoverFromPrivateKeyViewState {
    case loading(Double)
    case loaded
    case error(Error)
}
