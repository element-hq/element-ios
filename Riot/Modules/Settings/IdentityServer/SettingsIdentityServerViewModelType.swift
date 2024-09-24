// File created from ScreenTemplate
// $ createScreen.sh Test SettingsIdentityServer
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SettingsIdentityServerViewModelViewDelegate: AnyObject {
    func settingsIdentityServerViewModel(_ viewModel: SettingsIdentityServerViewModelType, didUpdateViewState viewSate: SettingsIdentityServerViewState)
}

/// Protocol describing the view model used by `SettingsIdentityServerViewController`
protocol SettingsIdentityServerViewModelType {
        
    var viewDelegate: SettingsIdentityServerViewModelViewDelegate? { get set }

    var identityServer: String? { get }
    
    func process(viewAction: SettingsIdentityServerViewAction)
}
