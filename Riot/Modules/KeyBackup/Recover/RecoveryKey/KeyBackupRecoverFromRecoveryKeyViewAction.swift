/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// KeyBackupRecoverFromRecoveryKeyViewController view actions exposed to view model
enum KeyBackupRecoverFromRecoveryKeyViewAction {
    case recover
    case unknownRecoveryKey
    case cancel
}
