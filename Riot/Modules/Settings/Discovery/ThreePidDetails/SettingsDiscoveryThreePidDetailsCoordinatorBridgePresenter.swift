// File created from FlowTemplate
// $ createRootCoordinator.sh Details SettingsDiscoveryThreePidDetails
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

/// SettingsDiscoveryThreePidDetailsCoordinatorBridgePresenter enables to start SettingsDiscoveryThreePidDetailsCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class SettingsDiscoveryThreePidDetailsCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let threePid: MX3PID
    
    private var coordinator: SettingsDiscoveryThreePidDetailsCoordinator?
    private var router: NavigationRouterType?
    
    // MARK: - Setup
    
    init(session: MXSession, medium: String, adress: String) {
        self.session = session
        self.threePid = MX3PID(medium: MX3PID.Medium(identifier: medium), address: adress)
        super.init()
    }
    
    // MARK: - Public
    
    func push(from navigationController: UINavigationController, animated: Bool, popCompletion: (() -> Void)?) {
        
        let router = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let settingsDiscoveryThreePidDetailsCoordinator = SettingsDiscoveryThreePidDetailsCoordinator(session: self.session, threePid: self.threePid)
        
        router.push(settingsDiscoveryThreePidDetailsCoordinator, animated: animated) { [weak self] in
            self?.coordinator = nil
            self?.router = nil
            popCompletion?()
        }
        
        settingsDiscoveryThreePidDetailsCoordinator.start()
        
        self.coordinator = settingsDiscoveryThreePidDetailsCoordinator
        self.router = router
    }
}
