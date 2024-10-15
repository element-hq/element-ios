/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, cancellable: Bool, dehydrationService: DehydrationService?) {
        let secretsRecoveryWithPassphraseViewModel = SecretsRecoveryWithPassphraseViewModel(recoveryService: recoveryService, recoveryGoal: recoveryGoal, dehydrationService: dehydrationService)
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
