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
