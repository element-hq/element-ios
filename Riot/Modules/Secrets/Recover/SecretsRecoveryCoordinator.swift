/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
        
        switch self.recoveryMode {
        case .onlyKey:
            rootCoordinator = self.createRecoverFromKeyCoordinator()
        case .passphraseOrKey:
            rootCoordinator = self.createRecoverFromPassphraseCoordinator()
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
        return self.navigationRouter
            .toPresentable()
            .vc_setModalFullScreen(!self.cancellable)
    }
    
    // MARK: - Private
    
    private var dehydrationService: DehydrationService? {
        if self.session.vc_homeserverConfiguration().encryption.deviceDehydrationEnabled {
            return self.session.crypto.dehydrationService
        }
        
        return nil
    }
    
    private func createRecoverFromKeyCoordinator() -> SecretsRecoveryWithKeyCoordinator {
        let coordinator = SecretsRecoveryWithKeyCoordinator(recoveryService: self.session.crypto.recoveryService,
                                                            recoveryGoal: self.recoveryGoal,
                                                            cancellable: self.cancellable,
                                                            dehydrationService: dehydrationService)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRecoverFromPassphraseCoordinator() -> SecretsRecoveryWithPassphraseCoordinator {
        let coordinator = SecretsRecoveryWithPassphraseCoordinator(recoveryService: self.session.crypto.recoveryService,
                                                                   recoveryGoal: self.recoveryGoal,
                                                                   cancellable: self.cancellable,
                                                                   dehydrationService: dehydrationService)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showRecoverFromKeyCoordinator() {
        let coordinator = self.createRecoverFromKeyCoordinator()
        coordinator.start()
        
        self.navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        self.add(childCoordinator: coordinator)
    }
    
    private func showResetSecrets() {
        let coordinator = SecretsResetCoordinator(session: self.session)
        coordinator.delegate = self
        coordinator.start()
        
        self.navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        self.add(childCoordinator: coordinator)
    }
    
    private func showSecureBackupSetup(checkKeyBackup: Bool) {
        let coordinator = SecureBackupSetupCoordinator(session: self.session, checkKeyBackup: checkKeyBackup, navigationRouter: self.navigationRouter, cancellable: self.cancellable)
        coordinator.delegate = self
        // Fix: calling coordinator.start() will update the navigationRouter without a popCompletion
        coordinator.start(popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        // Fix: do not push the presentable from the coordinator to the navigation router as this has already been done by coordinator.start().
        //      Also, coordinator.toPresentable() returns a navigation controller, which cannot be pushed into a navigation router.
        self.add(childCoordinator: coordinator)
    }
}

// MARK: - SecretsRecoveryWithKeyCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecretsRecoveryWithKeyCoordinatorDelegate {
    
    func secretsRecoveryWithKeyCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithKeyCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithKeyCoordinatorWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyCoordinatorType) {
        self.showResetSecrets()
    }
}

// MARK: - SecretsRecoveryWithPassphraseCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecretsRecoveryWithPassphraseCoordinatorDelegate {
    
    func secretsRecoveryWithPassphraseCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDoNotKnowPassphrase(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.showRecoverFromKeyCoordinator()
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithPassphraseCoordinatorWantsToResetSecrets(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {        
        self.showResetSecrets()
    }
}

// MARK: - SecretsResetCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecretsResetCoordinatorDelegate {
    func secretsResetCoordinatorDidResetSecrets(_ coordinator: SecretsResetCoordinatorType) {
        self.showSecureBackupSetup(checkKeyBackup: false)
    }
    
    func secretsResetCoordinatorDidCancel(_ coordinator: SecretsResetCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}

// MARK: - SecureBackupSetupCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecureBackupSetupCoordinatorDelegate {
    func secureBackupSetupCoordinatorDidComplete(_ coordinator: SecureBackupSetupCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secureBackupSetupCoordinatorDidCancel(_ coordinator: SecureBackupSetupCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}
