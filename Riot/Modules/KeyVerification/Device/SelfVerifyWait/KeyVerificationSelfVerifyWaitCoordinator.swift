// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyVerificationSelfVerifyWaitCoordinator: KeyVerificationSelfVerifyWaitCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyVerificationSelfVerifyWaitViewModel: KeyVerificationSelfVerifyWaitViewModelType
    private let keyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewController
    private let cancellable: Bool
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationSelfVerifyWaitCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isNewSignIn: Bool, cancellable: Bool) {
        let keyVerificationSelfVerifyWaitViewModel = KeyVerificationSelfVerifyWaitViewModel(session: session, isNewSignIn: isNewSignIn)
        let keyVerificationSelfVerifyWaitViewController = KeyVerificationSelfVerifyWaitViewController.instantiate(with: keyVerificationSelfVerifyWaitViewModel, cancellable: cancellable)
        self.keyVerificationSelfVerifyWaitViewModel = keyVerificationSelfVerifyWaitViewModel
        self.keyVerificationSelfVerifyWaitViewController = keyVerificationSelfVerifyWaitViewController
        self.cancellable = cancellable
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyVerificationSelfVerifyWaitViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyVerificationSelfVerifyWaitViewController
            .vc_setModalFullScreen(!self.cancellable)
    }
}

// MARK: - KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate
extension KeyVerificationSelfVerifyWaitCoordinator: KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate {
    
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinator(self, didAcceptKeyVerificationRequest: keyVerificationRequest)
    }
    
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didAcceptIncomingSASTransaction incomingSASTransaction: MXSASTransaction) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinator(self, didAcceptIncomingSASTransaction: incomingSASTransaction)
    }
    
    func keyVerificationSelfVerifyWaitViewModelDidCancel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinatorDidCancel(self)
    }
    
    func keyVerificationSelfVerifyWaitViewModel(_ coordinator: KeyVerificationSelfVerifyWaitViewModelType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinator(self, wantsToRecoverSecretsWith: secretsRecoveryMode)
    }
}
