// File created from FlowTemplate
// $ createRootCoordinator.sh KeyBackupSetup/SecureSetup SecureKeyBackupSetup
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

import UIKit

@objcMembers
final class SecureBackupSetupCoordinator: SecureBackupSetupCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let recoveryService: MXRecoveryService
    private let keyBackup: MXKeyBackup?
    private let checkKeyBackup: Bool
    private let homeserverEncryptionConfiguration: HomeserverEncryptionConfiguration
    private let allowOverwrite: Bool
    private let cancellable: Bool

    private var isBackupSetupMethodKeySupported: Bool {
        let homeserverEncryptionConfiguration = session.vc_homeserverConfiguration().encryption
        return homeserverEncryptionConfiguration.secureBackupSetupMethods.contains(.key)
    }

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecureBackupSetupCoordinatorDelegate?
    
    // MARK: - Setup
    
    /// Initializer
    /// - Parameters:
    ///   - session: The MXSession.
    ///   - checkKeyBackup: Indicate false to ignore existing key backup.
    ///   - navigationRouter: Use existing navigation router to plug this flow or let nil to use new one.
    ///   - cancellable: Whether secure backup can be cancelled
    init(session: MXSession, checkKeyBackup: Bool = true, allowOverwrite: Bool = false, navigationRouter: NavigationRouterType? = nil, cancellable: Bool) {
        self.session = session
        recoveryService = session.crypto.recoveryService
        keyBackup = session.crypto.backup
        self.checkKeyBackup = checkKeyBackup
        homeserverEncryptionConfiguration = session.vc_homeserverConfiguration().encryption
        self.allowOverwrite = allowOverwrite
        self.cancellable = cancellable
        
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        }
    }
    
    // MARK: - Public methods
    
    func start() {
        let rootViewController = createIntro()
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootViewController, animated: true, popCompletion: nil)
        } else {
            navigationRouter.setRootModule(rootViewController)
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter
            .toPresentable()
            .vc_setModalFullScreen(!cancellable)
    }
    
    // MARK: - Private methods

    private func createIntro() -> SecureBackupSetupIntroViewController {
        // TODO: Use a coordinator
        let viewModel = SecureBackupSetupIntroViewModel(keyBackup: keyBackup,
                                                        checkKeyBackup: checkKeyBackup,
                                                        homeserverEncryptionConfiguration: homeserverEncryptionConfiguration)
        let introViewController = SecureBackupSetupIntroViewController.instantiate(with: viewModel, cancellable: cancellable)
        introViewController.delegate = self
        return introViewController
    }
    
    private func showSetupKey(passphraseOnly: Bool, passphrase: String? = nil) {
        let coordinator = SecretsSetupRecoveryKeyCoordinator(recoveryService: recoveryService, passphrase: passphrase, passphraseOnly: passphraseOnly, allowOverwrite: allowOverwrite, cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showSetupPassphrase() {
        let coordinator = SecretsSetupRecoveryPassphraseCoordinator(passphraseInput: .new, cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()

        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showSetupPassphraseConfirmation(with passphrase: String) {
        let coordinator = SecretsSetupRecoveryPassphraseCoordinator(passphraseInput: .confirm(passphrase), cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showCancelAlert() {
        let alertController = UIAlertController(title: VectorL10n.secureKeyBackupSetupCancelAlertTitle,
                                                message: VectorL10n.secureKeyBackupSetupCancelAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: { _ in
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.keyBackupSetupSkipAlertSkipAction, style: .default, handler: { _ in
            self.delegate?.secureBackupSetupCoordinatorDidCancel(self)
        }))
        
        navigationRouter.present(alertController, animated: true)
    }
    
    private func showKeyBackupRestore() {
        guard let keyBackupVersion = keyBackup?.keyBackupVersion else {
            return
        }
        
        let coordinator = KeyBackupRecoverCoordinator(session: session, keyBackupVersion: keyBackupVersion, navigationRouter: navigationRouter)
        
        add(childCoordinator: coordinator)
        coordinator.delegate = self
        coordinator.start() // Will trigger view controller push
    }
    
    private func didCancel(showSkipAlert: Bool = true) {
        if showSkipAlert {
            showCancelAlert()
        } else {
            delegate?.secureBackupSetupCoordinatorDidCancel(self)
        }
    }
    
    private func didComplete() {
        delegate?.secureBackupSetupCoordinatorDidComplete(self)
    }
}

// MARK: - SecureBackupSetupIntroViewControllerDelegate

extension SecureBackupSetupCoordinator: SecureBackupSetupIntroViewControllerDelegate {
    func secureBackupSetupIntroViewControllerDidTapUseKey(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController) {
        showSetupKey(passphraseOnly: false)
    }
    
    func secureBackupSetupIntroViewControllerDidTapUsePassphrase(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController) {
        showSetupPassphrase()
    }
    
    func secureBackupSetupIntroViewControllerDidCancel(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController, showSkipAlert: Bool) {
        didCancel(showSkipAlert: showSkipAlert)
    }
    
    func secureBackupSetupIntroViewControllerDidTapConnectToKeyBackup(_ secureBackupSetupIntroViewController: SecureBackupSetupIntroViewController) {
        showKeyBackupRestore()
    }
}

// MARK: - SecretsSetupRecoveryKeyCoordinatorDelegate

extension SecureBackupSetupCoordinator: SecretsSetupRecoveryKeyCoordinatorDelegate {
    func secretsSetupRecoveryKeyCoordinatorDidComplete(_ coordinator: SecretsSetupRecoveryKeyCoordinatorType) {
        didComplete()
    }
    
    func secretsSetupRecoveryKeyCoordinatorDidFailed(_ coordinator: SecretsSetupRecoveryKeyCoordinatorType) {
        didCancel(showSkipAlert: false)
    }
    
    func secretsSetupRecoveryKeyCoordinatorDidCancel(_ coordinator: SecretsSetupRecoveryKeyCoordinatorType) {
        didCancel()
    }
}

// MARK: - SecretsSetupRecoveryPassphraseCoordinatorDelegate

extension SecureBackupSetupCoordinator: SecretsSetupRecoveryPassphraseCoordinatorDelegate {
    func secretsSetupRecoveryPassphraseCoordinator(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType, didEnterNewPassphrase passphrase: String) {
        showSetupPassphraseConfirmation(with: passphrase)
    }
    
    func secretsSetupRecoveryPassphraseCoordinator(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType, didConfirmPassphrase passphrase: String) {
        // Do not present recovery key export screen if secure backup setup key method is not supported
        showSetupKey(passphraseOnly: !isBackupSetupMethodKeySupported, passphrase: passphrase)
    }
    
    func secretsSetupRecoveryPassphraseCoordinatorDidCancel(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType) {
        didCancel()
    }
}

// MARK: - KeyBackupRecoverCoordinatorDelegate

extension SecureBackupSetupCoordinator: KeyBackupRecoverCoordinatorDelegate {
    func keyBackupRecoverCoordinatorDidCancel(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        navigationRouter.popToRootModule(animated: true)
    }
    
    func keyBackupRecoverCoordinatorDidRecover(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        navigationRouter.popToRootModule(animated: true)
    }
}
