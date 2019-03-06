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
    
    init(session: MXSession, keyBackupVersion: MXKeyBackupVersion) {
        self.session = session
        self.keyBackupVersion = keyBackupVersion
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
    }
    
    // MARK: - Public
    
    func start() {
        
        let rootCoordinator: Coordinator & Presentable
        
        // Check if a passphrase has been set for given backup
        if let megolmBackupAuthData = MXMegolmBackupAuthData(fromJSON: self.keyBackupVersion.authData), megolmBackupAuthData.privateKeySalt != nil {
            rootCoordinator = self.createRecoverFromPassphraseCoordinator()
        } else {
            rootCoordinator = self.createRecoverFromRecoveryKeyCoordinator()
        }
        
        rootCoordinator.start()
        
        self.add(childCoordinator: rootCoordinator)
        
        self.navigationRouter.setRootModule(rootCoordinator)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
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
    func KeyBackupRecoverSuccessViewControllerDidTapDone(_ keyBackupRecoverSuccessViewController: KeyBackupRecoverSuccessViewController) {
        self.delegate?.keyBackupRecoverCoordinatorDidRecover(self)
    }
}
