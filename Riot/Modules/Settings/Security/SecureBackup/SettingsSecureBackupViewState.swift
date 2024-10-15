/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

/// State of the Secure Backup section in securtiy settings.
///
/// It is a mixed of the state of the Secure Backup(4S) and the state of the Key Backup.
///
/// - loading: Load current state
/// - noSecureBackup: The account has no secure backup
/// - secureBackup: The account has a secure backup
enum SettingsSecureBackupViewState {
    case loading
    case noSecureBackup(KeyBackupState)
    case secureBackup(KeyBackupState)
    
    /// Internal key backup state. It is independent from the secure backup state.
    ///
    /// - noKeyBackup: There is no backup on the homeserver
    /// - keyBackup: There is a valid running backup on the homeserver. Keys are being sent to it
    /// - keyBackupNotTrusted: There is a backup on the homeserver but it is not trusted
    enum KeyBackupState {
        case noKeyBackup
        case keyBackup(MXKeyBackupVersion, MXKeyBackupVersionTrust, Progress?)
        case keyBackupNotTrusted(MXKeyBackupVersion, MXKeyBackupVersionTrust)
    }
}

/// State representing a network request made by the module
/// Only SettingsSecureBackupViewAction.delete generates such states
enum SettingsSecureBackupNetworkRequestViewState {
    case loading
    case loaded
    case error(Error)
}
