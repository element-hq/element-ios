// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SettingsDiscoveryThreePidDetailsViewController view actions exposed to view model
enum SettingsDiscoveryThreePidDetailsViewAction {
    case load
    case share
    case revoke
    case cancelThreePidValidation
    case confirmEmailValidation
    case confirmMSISDNValidation(code: String)
}
