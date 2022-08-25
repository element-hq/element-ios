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

import UIKit

@objcMembers
final class KeyBackupSetupCoordinator: KeyBackupSetupCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let isStartedFromSignOut: Bool
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupSetupCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isStartedFromSignOut: Bool) {
        navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.isStartedFromSignOut = isStartedFromSignOut
    }
    
    // MARK: - Public methods
    
    func start() {
        if session.crypto.recoveryService.hasRecovery() {
            showUnlockSecureBackup()
        } else {
            showSetupIntro()
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func showSetupIntro() {
        // Set key backup setup intro as root controller
        let keyBackupSetupIntroViewController = createSetupIntroViewController()
        keyBackupSetupIntroViewController.delegate = self
        navigationRouter.setRootModule(keyBackupSetupIntroViewController)
    }
    
    private func createSetupIntroViewController() -> KeyBackupSetupIntroViewController {
        let backupState = session.crypto.backup?.state ?? MXKeyBackupStateUnknown
        let isABackupAlreadyExists: Bool
        
        switch backupState {
        case MXKeyBackupStateUnknown, MXKeyBackupStateDisabled, MXKeyBackupStateCheckingBackUpOnHomeserver:
            isABackupAlreadyExists = false
        default:
            isABackupAlreadyExists = true
        }
        
        let encryptionKeysExportPresenter: EncryptionKeysExportPresenter?
        
        if isStartedFromSignOut {
            encryptionKeysExportPresenter = EncryptionKeysExportPresenter(session: session)
        } else {
            encryptionKeysExportPresenter = nil
        }
        
        return KeyBackupSetupIntroViewController.instantiate(isABackupAlreadyExists: isABackupAlreadyExists, encryptionKeysExportPresenter: encryptionKeysExportPresenter)
    }
    
    private func showUnlockSecureBackup() {
        let recoveryGoal: SecretsRecoveryGoal = .unlockSecureBackup { privateKey, completion in
            self.createKeyBackupUsingSecureBackup(privateKey: privateKey, completion: completion)
        }
        
        let coordinator = SecretsRecoveryCoordinator(session: session, recoveryMode: .passphraseOrKey, recoveryGoal: recoveryGoal, navigationRouter: navigationRouter, cancellable: true)
        coordinator.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
    }
    
    private func showSetupPassphrase(animated: Bool) {
        let keyBackupSetupPassphraseCoordinator = KeyBackupSetupPassphraseCoordinator(session: session)
        keyBackupSetupPassphraseCoordinator.delegate = self
        keyBackupSetupPassphraseCoordinator.start()
        
        add(childCoordinator: keyBackupSetupPassphraseCoordinator)
        navigationRouter.push(keyBackupSetupPassphraseCoordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: keyBackupSetupPassphraseCoordinator)
        }
    }
    
    private func showSetupRecoveryKeySuccess(with recoveryKey: String, animated: Bool) {
        let viewController = KeyBackupSetupSuccessFromRecoveryKeyViewController.instantiate(with: recoveryKey)
        viewController.delegate = self
        navigationRouter.push(viewController, animated: animated, popCompletion: nil)
    }
    
    private func showSetupPassphraseSuccess(with recoveryKey: String, animated: Bool) {
        let viewController = KeyBackupSetupSuccessFromPassphraseViewController.instantiate(with: recoveryKey)
        viewController.delegate = self
        navigationRouter.push(viewController, animated: animated, popCompletion: nil)
    }
    
    private func showSetupWithSecureBackupSuccess(animated: Bool) {
        let viewController = KeyBackupSetupSuccessFromSecureBackupViewController.instantiate()
        viewController.delegate = self
        navigationRouter.push(viewController, animated: animated, popCompletion: nil)
    }
    
    private func createKeyBackupUsingSecureBackup(privateKey: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let keyBackup = session.crypto.backup, let recoveryService = session.crypto.recoveryService else {
            return
        }
        
        keyBackup.prepareKeyBackupVersion(withPassword: nil, algorithm: nil, success: { megolmBackupCreationInfo in
            keyBackup.createKeyBackupVersion(megolmBackupCreationInfo, success: { _ in
                recoveryService.updateRecovery(forSecrets: [MXSecretId.keyBackup.takeUnretainedValue() as String], withPrivateKey: privateKey) {
                    completion(.success(()))
                } failure: { error in
                    completion(.failure(error))
                }
                
            }, failure: { error in
                completion(.failure(error))
            })
        }, failure: { error in
            completion(.failure(error))
        })
    }
}

// MARK: - KeyBackupSetupIntroViewControllerDelegate

extension KeyBackupSetupCoordinator: KeyBackupSetupIntroViewControllerDelegate {
    func keyBackupSetupIntroViewControllerDidTapSetupAction(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController) {
        showSetupPassphrase(animated: true)
    }
    
    func keyBackupSetupIntroViewControllerDidCancel(_ keyBackupSetupIntroViewController: KeyBackupSetupIntroViewController) {
        delegate?.keyBackupSetupCoordinatorDidCancel(self)
    }
}

// MARK: - KeyRecoveryPassphraseCoordinatorDelegate

extension KeyBackupSetupCoordinator: KeyBackupSetupPassphraseCoordinatorDelegate {
    func keyBackupSetupPassphraseCoordinator(_ keyBackupSetupPassphraseCoordinator: KeyBackupSetupPassphraseCoordinatorType, didCreateBackupFromPassphraseWithResultingRecoveryKey recoveryKey: String) {
        showSetupPassphraseSuccess(with: recoveryKey, animated: true)
    }
    
    func keyBackupSetupPassphraseCoordinator(_ keyBackupSetupPassphraseCoordinator: KeyBackupSetupPassphraseCoordinatorType, didCreateBackupFromRecoveryKey recoveryKey: String) {
        showSetupRecoveryKeySuccess(with: recoveryKey, animated: true)
    }
    
    func keyBackupSetupPassphraseCoordinatorDidCancel(_ keyBackupSetupPassphraseCoordinator: KeyBackupSetupPassphraseCoordinatorType) {
        delegate?.keyBackupSetupCoordinatorDidCancel(self)
    }
}

// MARK: - SecretsRecoveryCoordinatorDelegate

extension KeyBackupSetupCoordinator: SecretsRecoveryCoordinatorDelegate {
    func secretsRecoveryCoordinatorDidRecover(_ coordinator: SecretsRecoveryCoordinatorType) {
        showSetupWithSecureBackupSuccess(animated: true)
    }
    
    func secretsRecoveryCoordinatorDidCancel(_ coordinator: SecretsRecoveryCoordinatorType) {
        delegate?.keyBackupSetupCoordinatorDidCancel(self)
    }
}

// MARK: - KeyBackupSetupSuccessFromPassphraseViewControllerDelegate

extension KeyBackupSetupCoordinator: KeyBackupSetupSuccessFromPassphraseViewControllerDelegate {
    func keyBackupSetupSuccessFromPassphraseViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromPassphraseViewController) {
        delegate?.keyBackupSetupCoordinatorDidSetupRecoveryKey(self)
    }
}

// MARK: - KeyBackupSetupSuccessFromRecoveryKeyViewControllerDelegate

extension KeyBackupSetupCoordinator: KeyBackupSetupSuccessFromRecoveryKeyViewControllerDelegate {
    func keyBackupSetupSuccessFromRecoveryKeyViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromRecoveryKeyViewController) {
        delegate?.keyBackupSetupCoordinatorDidSetupRecoveryKey(self)
    }
}

// MARK: - KeyBackupSetupSuccessFromSecureBackupViewControllerDelegate

extension KeyBackupSetupCoordinator: KeyBackupSetupSuccessFromSecureBackupViewControllerDelegate {
    func keyBackupSetupSuccessFromSecureBackupViewControllerDidTapDoneAction(_ viewController: KeyBackupSetupSuccessFromSecureBackupViewController) {
        delegate?.keyBackupSetupCoordinatorDidSetupRecoveryKey(self)
    }
}
