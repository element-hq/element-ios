/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let keyBackup: MXKeyBackup
    private let keyBackupRecoverFromPassphraseViewController: KeyBackupRecoverFromPassphraseViewController
    private let keyBackupVersion: MXKeyBackupVersion
    private var keyBackupRecoverFromPassphraseViewModel: KeyBackupRecoverFromPassphraseViewModelType
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupRecoverFromPassphraseCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackup = keyBackup
        self.keyBackupVersion = keyBackupVersion
        
        let keyBackupRecoverFromPassphraseViewModel = KeyBackupRecoverFromPassphraseViewModel(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion)
        let keyBackupRecoverFromPassphraseViewController = KeyBackupRecoverFromPassphraseViewController.instantiate(with: keyBackupRecoverFromPassphraseViewModel)
        self.keyBackupRecoverFromPassphraseViewController = keyBackupRecoverFromPassphraseViewController
        self.keyBackupRecoverFromPassphraseViewModel = keyBackupRecoverFromPassphraseViewModel
    }
    
    // MARK: - Public
    
    func start() {
        self.keyBackupRecoverFromPassphraseViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupRecoverFromPassphraseViewController
    }
}

// MARK: - KeyBackupRecoverFromPassphraseViewModelCoordinatorDelegate
extension KeyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseViewModelCoordinatorDelegate {
    func keyBackupRecoverFromPassphraseViewModelDoNotKnowPassphrase(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType) {
        self.delegate?.keyBackupRecoverFromPassphraseCoordinatorDoNotKnowPassphrase(self)
    }
    
    func keyBackupRecoverFromPassphraseViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType) {
        self.delegate?.keyBackupRecoverFromPassphraseCoordinatorDidRecover(self)
    }
    
    func keyBackupRecoverFromPassphraseViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType) {
        self.delegate?.keyBackupRecoverFromPassphraseCoordinatorDidCancel(self)
    }        
}
