// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
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

final class SecretsSetupRecoveryPassphraseCoordinator: SecretsSetupRecoveryPassphraseCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private var secretsSetupRecoveryPassphraseViewModel: SecretsSetupRecoveryPassphraseViewModelType
    private let secretsSetupRecoveryPassphraseViewController: SecretsSetupRecoveryPassphraseViewController
    private let cancellable: Bool
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsSetupRecoveryPassphraseCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(passphraseInput: SecretsSetupRecoveryPassphraseInput, cancellable: Bool) {
        
        let secretsSetupRecoveryPassphraseViewModel = SecretsSetupRecoveryPassphraseViewModel(passphraseInput: passphraseInput)
        let secretsSetupRecoveryPassphraseViewController = SecretsSetupRecoveryPassphraseViewController.instantiate(with: secretsSetupRecoveryPassphraseViewModel, cancellable: cancellable)
        self.secretsSetupRecoveryPassphraseViewModel = secretsSetupRecoveryPassphraseViewModel
        self.secretsSetupRecoveryPassphraseViewController = secretsSetupRecoveryPassphraseViewController
        self.cancellable = cancellable
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.secretsSetupRecoveryPassphraseViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.secretsSetupRecoveryPassphraseViewController
            .vc_setModalFullScreen(!self.cancellable)
    }
}

// MARK: - SecretsSetupRecoveryPassphraseViewModelCoordinatorDelegate
extension SecretsSetupRecoveryPassphraseCoordinator: SecretsSetupRecoveryPassphraseViewModelCoordinatorDelegate {
    
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didEnterNewPassphrase passphrase: String) {
        self.delegate?.secretsSetupRecoveryPassphraseCoordinator(self, didEnterNewPassphrase: passphrase)
    }
    
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didConfirmPassphrase passphrase: String) {
        self.delegate?.secretsSetupRecoveryPassphraseCoordinator(self, didConfirmPassphrase: passphrase)
    }
    
    func secretsSetupRecoveryPassphraseViewModelDidCancel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType) {
        self.delegate?.secretsSetupRecoveryPassphraseCoordinatorDidCancel(self)
    }
}
