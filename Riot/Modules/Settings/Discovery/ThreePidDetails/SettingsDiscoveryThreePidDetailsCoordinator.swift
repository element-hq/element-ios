// File created from ScreenTemplate
// $ createScreen.sh Details SettingsDiscoveryThreePidDetails
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
