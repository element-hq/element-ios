/*
 Copyright 2020 New Vector Ltd
 
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

final class SecretsRecoveryCoordinator: SecretsRecoveryCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let navigationRouter: NavigationRouterType
    private let recoveryMode: SecretsRecoveryMode
    private let recoveryGoal: SecretsRecoveryGoal
    private let cancellable: Bool
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsRecoveryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, recoveryMode: SecretsRecoveryMode, recoveryGoal: SecretsRecoveryGoal, navigationRouter: NavigationRouterType? = nil, cancellable: Bool) {
        self.session = session
        self.recoveryMode = recoveryMode
        self.recoveryGoal = recoveryGoal
        self.cancellable = cancellable
        
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        }
    }
    
    // MARK: - Public
    
    func start() {
        let rootCoordinator: Coordinator & Presentable
        
        switch recoveryMode {
        case .onlyKey:
            rootCoordinator = createRecoverFromKeyCoordinator()
        case .passphraseOrKey:
            rootCoordinator = createRecoverFromPassphraseCoordinator()
        }
        
        rootCoordinator.start()
        
        add(childCoordinator: rootCoordinator)
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter
            .toPresentable()
            .vc_setModalFullScreen(!cancellable)
    }
    
    // MARK: - Private
    
    private func createRecoverFromKeyCoordinator() -> SecretsRecoveryWithKeyCoordinator {
        let coordinator = SecretsRecoveryWithKeyCoordinator(recoveryService: session.crypto.recoveryService, recoveryGoal: recoveryGoal, cancellable: cancellable)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRecoverFromPassphraseCoordinator() -> SecretsRecoveryWithPassphraseCoordinator {
        let coordinator = SecretsRecoveryWithPassphraseCoordinator(recoveryService: session.crypto.recoveryService, recoveryGoal: recoveryGoal, cancellable: cancellable)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showRecoverFromKeyCoordinator() {
        let coordinator = createRecoverFromKeyCoordinator()
        coordinator.start()
        
        navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        add(childCoordinator: coordinator)
    }
    
    private func showResetSecrets() {
        let coordinator = SecretsResetCoordinator(session: session)
        coordinator.delegate = self
        coordinator.start()
        
        navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        add(childCoordinator: coordinator)
    }
    
    private func showSecureBackupSetup(checkKeyBackup: Bool) {
        let coordinator = SecureBackupSetupCoordinator(session: session, checkKeyBackup: checkKeyBackup, navigationRouter: navigationRouter, cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        add(childCoordinator: coordinator)
    }
}

// MARK: - SecretsRecoveryWithKeyCoordinatorDelegate

extension SecretsRecoveryCoordinator: SecretsRecoveryWithKeyCoordinatorDelegate {
    func secretsRecoveryWithKeyCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithKeyCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithKeyCoordinatorWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyCoordinatorType) {
        showResetSecrets()
    }
}

// MARK: - SecretsRecoveryWithPassphraseCoordinatorDelegate

extension SecretsRecoveryCoordinator: SecretsRecoveryWithPassphraseCoordinatorDelegate {
    func secretsRecoveryWithPassphraseCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDoNotKnowPassphrase(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        showRecoverFromKeyCoordinator()
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithPassphraseCoordinatorWantsToResetSecrets(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        showResetSecrets()
    }
}

// MARK: - SecretsResetCoordinatorDelegate

extension SecretsRecoveryCoordinator: SecretsResetCoordinatorDelegate {
    func secretsResetCoordinatorDidResetSecrets(_ coordinator: SecretsResetCoordinatorType) {
        showSecureBackupSetup(checkKeyBackup: false)
    }
    
    func secretsResetCoordinatorDidCancel(_ coordinator: SecretsResetCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}

// MARK: - SecureBackupSetupCoordinatorDelegate

extension SecretsRecoveryCoordinator: SecureBackupSetupCoordinatorDelegate {
    func secureBackupSetupCoordinatorDidComplete(_ coordinator: SecureBackupSetupCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secureBackupSetupCoordinatorDidCancel(_ coordinator: SecureBackupSetupCoordinatorType) {
        delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}
