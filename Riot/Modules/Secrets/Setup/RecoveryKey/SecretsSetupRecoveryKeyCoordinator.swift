// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class SecretsSetupRecoveryKeyCoordinator: SecretsSetupRecoveryKeyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var secretsSetupRecoveryKeyViewModel: SecretsSetupRecoveryKeyViewModelType
    private let secretsSetupRecoveryKeyViewController: SecretsSetupRecoveryKeyViewController
    private let cancellable: Bool
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsSetupRecoveryKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService,
         passphrase: String?,
         passphraseOnly: Bool,
         allowOverwrite: Bool = false,
         cancellable: Bool,
         dehydrationService: DehydrationService?) {
        let secretsSetupRecoveryKeyViewModel = SecretsSetupRecoveryKeyViewModel(recoveryService: recoveryService,
                                                                                passphrase: passphrase,
                                                                                passphraseOnly: passphraseOnly,
                                                                                allowOverwrite: allowOverwrite,
                                                                                dehydrationService: dehydrationService)
        let secretsSetupRecoveryKeyViewController = SecretsSetupRecoveryKeyViewController.instantiate(with: secretsSetupRecoveryKeyViewModel, cancellable: cancellable)
        self.secretsSetupRecoveryKeyViewModel = secretsSetupRecoveryKeyViewModel
        self.secretsSetupRecoveryKeyViewController = secretsSetupRecoveryKeyViewController
        self.cancellable = cancellable
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.secretsSetupRecoveryKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.secretsSetupRecoveryKeyViewController
            .vc_setModalFullScreen(!self.cancellable)
    }
}

// MARK: - SecretsSetupRecoveryKeyViewModelCoordinatorDelegate
extension SecretsSetupRecoveryKeyCoordinator: SecretsSetupRecoveryKeyViewModelCoordinatorDelegate {
    
    func secretsSetupRecoveryKeyViewModelDidComplete(_ viewModel: SecretsSetupRecoveryKeyViewModelType) {
        self.delegate?.secretsSetupRecoveryKeyCoordinatorDidComplete(self)
    }
    
    func secretsSetupRecoveryKeyViewModelDidFailed(_ viewModel: SecretsSetupRecoveryKeyViewModelType) {
        self.delegate?.secretsSetupRecoveryKeyCoordinatorDidFailed(self)
    }
    
    func secretsSetupRecoveryKeyViewModelDidCancel(_ viewModel: SecretsSetupRecoveryKeyViewModelType) {
        self.delegate?.secretsSetupRecoveryKeyCoordinatorDidCancel(self)
    }
}
