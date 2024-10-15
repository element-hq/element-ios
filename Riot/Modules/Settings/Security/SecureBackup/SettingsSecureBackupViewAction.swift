/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

enum SettingsSecureBackupViewAction {
    case load
    case createSecureBackup
    case resetSecureBackup
    case createKeyBackup
    case restoreFromKeyBackup(MXKeyBackupVersion)
    case confirmDeleteKeyBackup(MXKeyBackupVersion)
    case deleteKeyBackup(MXKeyBackupVersion)
}
