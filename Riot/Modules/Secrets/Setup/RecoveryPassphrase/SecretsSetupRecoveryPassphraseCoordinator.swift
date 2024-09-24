// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
