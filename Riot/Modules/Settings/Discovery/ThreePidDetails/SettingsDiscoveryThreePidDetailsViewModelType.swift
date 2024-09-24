// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SettingsDiscoveryThreePidDetailsViewModelViewDelegate: AnyObject {
    func settingsDiscoveryThreePidDetailsViewModel(_ viewModel: SettingsDiscoveryThreePidDetailsViewModelType, didUpdateViewState viewSate: SettingsDiscoveryThreePidDetailsViewState)
}

/// Protocol describing the view model used by `SettingsDiscoveryThreePidDetailsViewController`
protocol SettingsDiscoveryThreePidDetailsViewModelType {
    
    var threePid: MX3PID { get }
            
    var viewDelegate: SettingsDiscoveryThreePidDetailsViewModelViewDelegate? { get set }
    
    func process(viewAction: SettingsDiscoveryThreePidDetailsViewAction)
}
