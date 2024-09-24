// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class SettingsDiscoveryThreePidDetailsCoordinator: SettingsDiscoveryThreePidDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var settingsDiscoveryThreePidDetailsViewModel: SettingsDiscoveryThreePidDetailsViewModelType
    private let settingsDiscoveryThreePidDetailsViewController: SettingsDiscoveryThreePidDetailsViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []        
    
    // MARK: - Setup
    
    init(session: MXSession, threePid: MX3PID) {
        self.session = session
        
        let settingsDiscoveryThreePidDetailsViewModel = SettingsDiscoveryThreePidDetailsViewModel(session: self.session, threePid: threePid)
        let settingsDiscoveryThreePidDetailsViewController = SettingsDiscoveryThreePidDetailsViewController.instantiate(with: settingsDiscoveryThreePidDetailsViewModel)
        self.settingsDiscoveryThreePidDetailsViewModel = settingsDiscoveryThreePidDetailsViewModel
        self.settingsDiscoveryThreePidDetailsViewController = settingsDiscoveryThreePidDetailsViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
    }
    
    func toPresentable() -> UIViewController {
        return self.settingsDiscoveryThreePidDetailsViewController
    }
}
