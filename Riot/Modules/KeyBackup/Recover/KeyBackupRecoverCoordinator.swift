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

final class KeyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let navigationRouter: NavigationRouterType
    private let keyBackupVersion: MXKeyBackupVersion
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupRecoverCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, keyBackupVersion: MXKeyBackupVersion, navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.keyBackupVersion = keyBackupVersion
        
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        }
    }
    
    // MARK: - Public
        
    func start() {
        
        let rootCoordinator: Coordinator & Presentable
        
        // Check if we have the private key locally
        if self.session.crypto.backup.hasPrivateKeyInCryptoStore {
            rootCoordinator = self.createRecoverFromPrivateKeyCoordinator()
        } else {
            rootCoordinator = self.createRecoverWithUserInteractionCoordinator()
        }
        
        rootCoordinator.start()
        
        self.add(childCoordinator: rootCoordinator)
        
        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    private func createRecoverWithUserInteractionCoordinator() -> Coordinator & Presentable {
        let coordinator: Coordinator & Presentable
        
        // Check if a passphrase has been set for given backup
        if self.keyBackupVersion.authData["private_key_salt"] != nil {
            coordinator = self.createRecoverFromPassphraseCoordinator()
        } else {
            coordinator = self.createRecoverFromRecoveryKeyCoordinator()
        }
        return coordinator
    }
    
    private func createRecoverFromPrivateKeyCoordinator() -> KeyBackupRecoverFromPrivateKeyCoordinator {
        let coordinator = KeyBackupRecoverFromPrivateKeyCoordinator(keyBackup: self.session.crypto.backup, keyBackupVersion: self.keyBackupVersion)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRecoverFromPassphraseCoordinator() -> KeyBackupRecoverFromPassphraseCoordinator {
        let coordinator = KeyBackupRecoverFromPassphraseCoordinator(keyBackup: self.session.crypto.backup, keyBackupVersion: self.keyBackupVersion)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRecoverFromRecoveryKeyCoordinator() -> KeyBackupRecoverFromRecoveryKeyCoordinator {
        let coordinator = KeyBackupRecoverFromRecoveryKeyCoordinator(keyBackup: self.session.crypto.backup, keyBackupVersion: self.keyBackupVersion)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showRecoverFromRecoveryKey() {
        let coordinator = self.createRecoverFromRecoveryKeyCoordinator()
        
        self.add(childCoordinator: coordinator)
        
        self.navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
        
        coordinator.start()
    }
    
    private func showRecoverSuccess() {
        let keyBackupRecoverSuccessViewController = KeyBackupRecoverSuccessViewController.instantiate()
        keyBackupRecoverSuccessViewController.delegate = self
        self.navigationRouter.push(keyBackupRecoverSuccessViewController, animated: true, popCompletion: nil)
    }
    
    private func showRecoverFallback() {
        let coordinator = self.createRecoverWithUserInteractionCoordinator()
        self.add(childCoordinator: coordinator)
        
        // Skip the previously displayed KeyBackupRecoverFromPrivateKeyCoordinator in the navigation stack
        self.navigationRouter.setRootModule(coordinator)
        
        coordinator.start()
    }
}

// MARK: - KeyBackupRecoverFromPassphraseCoordinatorDelegate
extension KeyBackupRecoverCoordinator: KeyBackupRecoverFromPrivateKeyCoordinatorDelegate {
    
    func keyBackupRecoverFromPrivateKeyCoordinatorDidRecover(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType) {
        self.showRecoverSuccess()
    }
    
    func keyBackupRecoverFromPrivateKeyCoordinatorDidPrivateKeyFail(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType) {
        // The private key did not work. Ask the user to enter their passphrase or recovery key
        self.showRecoverFallback()
    }
    
    func keyBackupRecoverFromPrivateKeyCoordinatorDidCancel(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorDidCancel(self)
    }
}

// MARK: - KeyBackupRecoverFromPassphraseCoordinatorDelegate
extension KeyBackupRecoverCoordinator: KeyBackupRecoverFromPassphraseCoordinatorDelegate {
    func keyBackupRecoverFromPassphraseCoordinatorDidRecover(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType) {
        self.showRecoverSuccess()
    }
    
    func keyBackupRecoverFromPassphraseCoordinatorDoNotKnowPassphrase(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType) {
        self.showRecoverFromRecoveryKey()
    }
    
    func keyBackupRecoverFromPassphraseCoordinatorDidCancel(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorDidCancel(self)
    }
}

// MARK: - KeyBackupRecoverFromRecoveryKeyCoordinatorDelegate
extension KeyBackupRecoverCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorDelegate {
    func keyBackupRecoverFromPassphraseCoordinatorDidRecover(_ keyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorType) {
        self.showRecoverSuccess()
    }
    
    func keyBackupRecoverFromPassphraseCoordinatorDidCancel(_ keyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorDidCancel(self)
    }
}

// MARK: - KeyBackupRecoverSuccessViewControllerDelegate
extension KeyBackupRecoverCoordinator: KeyBackupRecoverSuccessViewControllerDelegate {
    func keyBackupRecoverSuccessViewControllerDidTapDone(_ keyBackupRecoverSuccessViewController: KeyBackupRecoverSuccessViewController) {
        self.delegate?.keyBackupRecoverCoordinatorDidRecover(self)
    }
}
