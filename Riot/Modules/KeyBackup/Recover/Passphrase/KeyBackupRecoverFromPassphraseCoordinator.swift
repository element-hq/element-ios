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
