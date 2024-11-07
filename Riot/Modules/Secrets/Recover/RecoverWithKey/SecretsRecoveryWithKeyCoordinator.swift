/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, cancellable: Bool, dehydrationService: DehydrationService?) {
        
        let secretsRecoveryWithKeyViewModel = SecretsRecoveryWithKeyViewModel(recoveryService: recoveryService, recoveryGoal: recoveryGoal, dehydrationService: dehydrationService)
        let secretsRecoveryWithKeyViewController = SecretsRecoveryWithKeyViewController.instantiate(with: secretsRecoveryWithKeyViewModel, cancellable: cancellable)
        self.secretsRecoveryWithKeyViewController = secretsRecoveryWithKeyViewController
        self.secretsRecoveryWithKeyViewModel = secretsRecoveryWithKeyViewModel
        self.cancellable = cancellable
    }
    
    // MARK: - Public
    
    func start() {
        self.secretsRecoveryWithKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.secretsRecoveryWithKeyViewController
            .vc_setModalFullScreen(!self.cancellable)
    }
}

// MARK: - secretsRecoveryWithKeyViewModelCoordinatorDelegate
extension SecretsRecoveryWithKeyCoordinator: SecretsRecoveryWithKeyViewModelCoordinatorDelegate {
    func secretsRecoveryWithKeyViewModelDidRecover(_ viewModel: SecretsRecoveryWithKeyViewModelType) {        self.delegate?.secretsRecoveryWithKeyCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithKeyViewModelDidCancel(_ viewModel: SecretsRecoveryWithKeyViewModelType) {        self.delegate?.secretsRecoveryWithKeyCoordinatorDidCancel(self)
    }
    
    func secretsRecoveryWithKeyViewModelWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyViewModelType) {
        self.delegate?.secretsRecoveryWithKeyCoordinatorWantsToResetSecrets(self)
    }
}
