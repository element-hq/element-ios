// File created from FlowTemplate
// $ createRootCoordinator.sh Details SettingsDiscoveryThreePidDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
