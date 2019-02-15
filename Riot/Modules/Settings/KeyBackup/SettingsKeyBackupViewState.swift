/*
 Copyright 2019 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
