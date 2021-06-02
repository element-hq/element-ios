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

@objc protocol KeyBackupRecoverCoordinatorBridgePresenterDelegate {
    func keyBackupRecoverCoordinatorBridgePresenterDidCancel(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter)
    func keyBackupRecoverCoordinatorBridgePresenterDidRecover(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter)
}

/// KeyBackupRecoverCoordinatorBridgePresenter enables to start KeyBackupRecoverCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class KeyBackupRecoverCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let keyBackupVersion: MXKeyBackupVersion
    private var coordinator: KeyBackupRecoverCoordinator?
    
    // MARK: Public
    
    weak var delegate: KeyBackupRecoverCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, keyBackupVersion: MXKeyBackupVersion) {
        self.session = session
        self.keyBackupVersion = keyBackupVersion
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let keyBackupSetupCoordinator = KeyBackupRecoverCoordinator(session: self.session, keyBackupVersion: keyBackupVersion)
        keyBackupSetupCoordinator.delegate = self
        viewController.present(keyBackupSetupCoordinator.toPresentable(), animated: animated, completion: nil)
        keyBackupSetupCoordinator.start()
        
        self.coordinator = keyBackupSetupCoordinator
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
        
        MXLog.debug("[KeyBackupRecoverCoordinatorBridgePresenter] Push complete security from \(navigationController)")
        
        let navigationRouter = NavigationRouter(navigationController: navigationController)
        
        let keyBackupSetupCoordinator = KeyBackupRecoverCoordinator(session: self.session, keyBackupVersion: keyBackupVersion, navigationRouter: navigationRouter)
        keyBackupSetupCoordinator.delegate = self
        keyBackupSetupCoordinator.start() // Will trigger view controller push
        
        self.coordinator = keyBackupSetupCoordinator
    }
    
    func dismiss(animated: Bool) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
        }
    }
}

// MARK: - KeyBackupRecoverCoordinatorDelegate
extension KeyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorDelegate {
    func keyBackupRecoverCoordinatorDidRecover(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorBridgePresenterDidRecover(self)
    }
    
    func keyBackupRecoverCoordinatorDidCancel(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorBridgePresenterDidCancel(self)
    }
}
