// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SettingsIdentityServerViewController view actions exposed to view model
enum SettingsIdentityServerViewAction {
    case load
    case add(identityServer: String)
    case change(identityServer: String)
    case disconnect
}
