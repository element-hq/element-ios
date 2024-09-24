// File created from FlowTemplate
// $ createRootCoordinator.sh Test SettingsIdentityServer
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol SettingsIdentityServerCoordinatorBridgePresenterDelegate {
    func settingsIdentityServerCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SettingsIdentityServerCoordinatorBridgePresenter)
}

/// SettingsIdentityServerCoordinatorBridgePresenter enables to start SettingsIdentityServerCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class SettingsIdentityServerCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var router: NavigationRouterType?
    private var coordinator: SettingsIdentityServerCoordinator?
    
    // MARK: Public
    
    weak var delegate: SettingsIdentityServerCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    func push(from navigationController: UINavigationController, animated: Bool, popCompletion: (() -> Void)?) {
        
        let router = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let settingsIdentityServerCoordinator = SettingsIdentityServerCoordinator(session: self.session)
        
        router.push(settingsIdentityServerCoordinator, animated: animated) { [weak self] in
            self?.coordinator = nil
            self?.router = nil
            popCompletion?()
        }
        
        settingsIdentityServerCoordinator.start()
        
        self.coordinator = settingsIdentityServerCoordinator
        self.router = router
    }
}
