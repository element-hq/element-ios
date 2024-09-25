/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyBackupSetupPassphraseCoordinator: KeyBackupSetupPassphraseCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyBackupSetupPassphraseViewModel: KeyBackupSetupPassphraseViewModelType
    private let keyBackupSetupPassphraseViewController: KeyBackupSetupPassphraseViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupSetupPassphraseCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup) {
        let keyBackupSetupPassphraseViewModel = KeyBackupSetupPassphraseViewModel(keyBackup: keyBackup)
        let keyBackupSetupPassphraseViewController = KeyBackupSetupPassphraseViewController.instantiate(with: keyBackupSetupPassphraseViewModel)
        self.keyBackupSetupPassphraseViewModel = keyBackupSetupPassphraseViewModel
        self.keyBackupSetupPassphraseViewController = keyBackupSetupPassphraseViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyBackupSetupPassphraseViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupSetupPassphraseViewController
    }
}

// MARK: - KeyBackupSetupPassphraseViewModelCoordinatorDelegate
extension KeyBackupSetupPassphraseCoordinator: KeyBackupSetupPassphraseViewModelCoordinatorDelegate {
    
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromPassphraseWithResultingRecoveryKey recoveryKey: String) {
        self.delegate?.keyBackupSetupPassphraseCoordinator(self, didCreateBackupFromPassphraseWithResultingRecoveryKey: recoveryKey)
    }
    
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromRecoveryKey recoveryKey: String) {
        self.delegate?.keyBackupSetupPassphraseCoordinator(self, didCreateBackupFromRecoveryKey: recoveryKey)
    }
    
    func keyBackupSetupPassphraseViewModelDidCancel(_ viewModel: KeyBackupSetupPassphraseViewModelType) {
        self.delegate?.keyBackupSetupPassphraseCoordinatorDidCancel(self)
    }
}
