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

final class KeyBackupSetupRecoveryKeyCoordinator: KeyBackupSetupRecoveryKeyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyBackupSetupRecoveryKeyViewModel: KeyBackupSetupRecoveryKeyViewModelType
    private let keyBackupSetupRecoveryKeyViewController: KeyBackupSetupRecoveryKeyViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupSetupRecoveryKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, megolmBackupCreationInfo: MXMegolmBackupCreationInfo) {
        let keyBackup = MXKeyBackup(matrixSession: session)
        let keyBackupSetupRecoveryKeyViewModel = KeyBackupSetupRecoveryKeyViewModel(keyBackup: keyBackup, megolmBackupCreationInfo: megolmBackupCreationInfo)
        let keyBackupSetupRecoveryKeyViewController = KeyBackupSetupRecoveryKeyViewController.instantiate(with: keyBackupSetupRecoveryKeyViewModel)
        self.keyBackupSetupRecoveryKeyViewModel = keyBackupSetupRecoveryKeyViewModel
        self.keyBackupSetupRecoveryKeyViewController = keyBackupSetupRecoveryKeyViewController
    }
    
    // MARK: - Public methods
    
    func start() {
        self.keyBackupSetupRecoveryKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupSetupRecoveryKeyViewController
    }
}

// MARK: - KeyBackupSetupRecoveryKeyViewModelCoordinatorDelegate
extension KeyBackupSetupRecoveryKeyCoordinator: KeyBackupSetupRecoveryKeyViewModelCoordinatorDelegate {
    
    func keyBackupSetupRecoveryKeyViewModelDidCancel(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType) {
        self.delegate?.keyBackupSetupRecoveryKeyCoordinatorDidCancel(self)
    }
    
    func keyBackupSetupRecoveryKeyViewModelDidCreateBackup(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType) {
        self.delegate?.keyBackupSetupRecoveryKeyCoordinatorDidCreateBackup(self)
    }
}
