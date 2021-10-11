// File created from FlowTemplate
// $ createRootCoordinator.sh Test SettingsIdentityServer
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
