/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// SettingsKeyBackup view state
///
/// - checkingBackup: Load current backup on the homeserver
/// - checkError: Fail to load current backup data
/// - noBackup: There is no backup on the homeserver
/// - backup: There is a valid backup on the homeserver. All keys have been backed up to it
/// - backupAndRunning: There is a valid backup on the homeserver. Keys are being sent to it
/// - backupButNotVerified: There is a backup on the homeserver but it has not been verified yet
enum SettingsKeyBackupViewState {
    case checkingBackup
    case noBackup
    case backup(MXKeyBackupVersion, MXKeyBackupVersionTrust)
    case backupAndRunning(MXKeyBackupVersion, MXKeyBackupVersionTrust, Progress)
    case backupNotTrusted(MXKeyBackupVersion, MXKeyBackupVersionTrust)
}

/// State representing a network request made by the module
/// Only SettingsKeyBackupViewAction.delete generates such states
enum SettingsKeyBackupNetworkRequestViewState {
    case loading
    case loaded
    case error(Error)
}
