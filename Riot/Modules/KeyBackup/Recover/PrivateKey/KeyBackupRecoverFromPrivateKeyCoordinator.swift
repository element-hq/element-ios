// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
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

import Foundation
import UIKit

final class KeyBackupRecoverFromPrivateKeyCoordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyBackupRecoverFromPrivateKeyViewModel: KeyBackupRecoverFromPrivateKeyViewModelType
    private let keyBackupRecoverFromPrivateKeyViewController: KeyBackupRecoverFromPrivateKeyViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupRecoverFromPrivateKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        
        let keyBackupRecoverFromPrivateKeyViewModel = KeyBackupRecoverFromPrivateKeyViewModel(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion)
        let keyBackupRecoverFromPrivateKeyViewController = KeyBackupRecoverFromPrivateKeyViewController.instantiate(with: keyBackupRecoverFromPrivateKeyViewModel)
        self.keyBackupRecoverFromPrivateKeyViewModel = keyBackupRecoverFromPrivateKeyViewModel
        self.keyBackupRecoverFromPrivateKeyViewController = keyBackupRecoverFromPrivateKeyViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyBackupRecoverFromPrivateKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupRecoverFromPrivateKeyViewController
    }
}

// MARK: - KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate
extension KeyBackupRecoverFromPrivateKeyCoordinator: KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate {
    func keyBackupRecoverFromPrivateKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidRecover(self)
    }
    
    func keyBackupRecoverFromPrivateKeyViewModelDidPrivateKeyFail(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidPrivateKeyFail(self)
    }
    
    func keyBackupRecoverFromPrivateKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidCancel(self)
    }
}
