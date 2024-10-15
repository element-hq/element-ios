/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorType {    
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let keyBackup: MXKeyBackup
    private let keyBackupRecoverFromRecoveryKeyViewController: KeyBackupRecoverFromRecoveryKeyViewController
    private let keyBackupVersion: MXKeyBackupVersion
    private let keyBackupRecoverFromRecoveryKeyViewModel: KeyBackupRecoverFromRecoveryKeyViewModel
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupRecoverFromRecoveryKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackup = keyBackup
        self.keyBackupVersion = keyBackupVersion
        
        let keyBackupRecoverFromRecoveryKeyViewModel = KeyBackupRecoverFromRecoveryKeyViewModel(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion)
        let keyBackupRecoverFromRecoveryKeyViewController = KeyBackupRecoverFromRecoveryKeyViewController.instantiate(with: keyBackupRecoverFromRecoveryKeyViewModel)
        self.keyBackupRecoverFromRecoveryKeyViewController = keyBackupRecoverFromRecoveryKeyViewController
        self.keyBackupRecoverFromRecoveryKeyViewModel = keyBackupRecoverFromRecoveryKeyViewModel
    }
    
    // MARK: - Public
    
    func start() {
        self.keyBackupRecoverFromRecoveryKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupRecoverFromRecoveryKeyViewController
    }
}

// MARK: - KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate
extension KeyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate {
    func keyBackupRecoverFromRecoveryKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPassphraseCoordinatorDidRecover(self)
    }
    
    func keyBackupRecoverFromRecoveryKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPassphraseCoordinatorDidCancel(self)
    }
}
