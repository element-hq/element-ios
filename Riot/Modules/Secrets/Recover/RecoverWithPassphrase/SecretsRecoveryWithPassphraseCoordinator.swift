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

final class SecretsRecoveryWithPassphraseCoordinator: SecretsRecoveryWithPassphraseCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let secretsRecoveryWithPassphraseViewController: SecretsRecoveryWithPassphraseViewController
    private var secretsRecoveryWithPassphraseViewModel: SecretsRecoveryWithPassphraseViewModelType
    private let cancellable: Bool
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsRecoveryWithPassphraseCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, cancellable: Bool) {
        let secretsRecoveryWithPassphraseViewModel = SecretsRecoveryWithPassphraseViewModel(recoveryService: recoveryService, recoveryGoal: recoveryGoal)
        let secretsRecoveryWithPassphraseViewController = SecretsRecoveryWithPassphraseViewController.instantiate(with: secretsRecoveryWithPassphraseViewModel, cancellable: cancellable)
        self.secretsRecoveryWithPassphraseViewController = secretsRecoveryWithPassphraseViewController
        self.secretsRecoveryWithPassphraseViewModel = secretsRecoveryWithPassphraseViewModel
        self.cancellable = cancellable
    }
    
    // MARK: - Public
    
    func start() {
        self.secretsRecoveryWithPassphraseViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.secretsRecoveryWithPassphraseViewController
            .vc_setModalFullScreen(!self.cancellable)
    }
}

// MARK: - SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate
extension SecretsRecoveryWithPassphraseCoordinator: SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate {
    func secretsRecoveryWithPassphraseViewModelWantsToRecoverByKey(_ viewModel: SecretsRecoveryWithPassphraseViewModelType) {
        self.delegate?.secretsRecoveryWithPassphraseCoordinatorDoNotKnowPassphrase(self)
    }
    
    func secretsRecoveryWithPassphraseViewModelDidRecover(_ viewModel: SecretsRecoveryWithPassphraseViewModelType) {
        self.delegate?.secretsRecoveryWithPassphraseCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithPassphraseViewModelDidCancel(_ viewModel: SecretsRecoveryWithPassphraseViewModelType) {
        self.delegate?.secretsRecoveryWithPassphraseCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithPassphraseViewModelWantsToResetSecrets(_ viewModel: SecretsRecoveryWithPassphraseViewModelType) {
        self.delegate?.secretsRecoveryWithPassphraseCoordinatorWantsToResetSecrets(self)
    }
}
