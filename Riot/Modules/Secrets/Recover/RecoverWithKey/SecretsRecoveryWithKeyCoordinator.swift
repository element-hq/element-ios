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

final class SecretsRecoveryWithKeyCoordinator: SecretsRecoveryWithKeyCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let secretsRecoveryWithKeyViewController: SecretsRecoveryWithKeyViewController
    private let secretsRecoveryWithKeyViewModel: SecretsRecoveryWithKeyViewModel
    private let cancellable: Bool
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsRecoveryWithKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, cancellable: Bool) {
        let secretsRecoveryWithKeyViewModel = SecretsRecoveryWithKeyViewModel(recoveryService: recoveryService, recoveryGoal: recoveryGoal)
        let secretsRecoveryWithKeyViewController = SecretsRecoveryWithKeyViewController.instantiate(with: secretsRecoveryWithKeyViewModel, cancellable: cancellable)
        self.secretsRecoveryWithKeyViewController = secretsRecoveryWithKeyViewController
        self.secretsRecoveryWithKeyViewModel = secretsRecoveryWithKeyViewModel
        self.cancellable = cancellable
    }
    
    // MARK: - Public
    
    func start() {
        secretsRecoveryWithKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        secretsRecoveryWithKeyViewController
            .vc_setModalFullScreen(!cancellable)
    }
}

// MARK: - secretsRecoveryWithKeyViewModelCoordinatorDelegate

extension SecretsRecoveryWithKeyCoordinator: SecretsRecoveryWithKeyViewModelCoordinatorDelegate {
    func secretsRecoveryWithKeyViewModelDidRecover(_ viewModel: SecretsRecoveryWithKeyViewModelType) { delegate?.secretsRecoveryWithKeyCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithKeyViewModelDidCancel(_ viewModel: SecretsRecoveryWithKeyViewModelType) { delegate?.secretsRecoveryWithKeyCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithKeyViewModelWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyViewModelType) {
        delegate?.secretsRecoveryWithKeyCoordinatorWantsToResetSecrets(self)
    }
}
