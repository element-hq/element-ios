/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SettingsDiscoveryTableViewSection view state
enum SettingsDiscoveryViewState {
    case loading
    case loaded(displayMode: SettingsDiscoveryDisplayMode)
    case error(Error)
}

/// SettingsDiscoveryTableViewSection `loaded` view state dipslay modes
///
/// - noIdentityServer: No identity server configured.
/// - termsNotSigned: Identity server terms are not signed.
/// - noThreePidsAdded: No three pids added to the user HS account.
/// - threePidsAdded: Three pids added to the user HS account.
enum SettingsDiscoveryDisplayMode {
    case noIdentityServer
    case termsNotSigned(host: String)
    case noThreePidsAdded
    case threePidsAdded(emails: [MX3PID], phoneNumbers: [MX3PID])
}
