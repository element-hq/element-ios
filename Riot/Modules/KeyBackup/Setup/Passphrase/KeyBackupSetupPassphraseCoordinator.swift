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
