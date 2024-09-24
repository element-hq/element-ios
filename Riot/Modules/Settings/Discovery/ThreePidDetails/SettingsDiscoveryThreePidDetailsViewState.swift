// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SettingsDiscoveryThreePidDetailsViewController view state
enum SettingsDiscoveryThreePidDetailsViewState {
    case loading
    case loaded(displayMode: SettingsDiscoveryThreePidDetailsDisplayMode)
    case error(Error)
}

enum SettingsDiscoveryThreePidDetailsDisplayMode {
    case share
    case revoke
    case pendingThreePidVerification
}
