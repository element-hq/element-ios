// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

final class KeyVerificationSelfVerifyWaitCoordinator: KeyVerificationSelfVerifyWaitCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var keyVerificationSelfVerifyWaitViewModel: KeyVerificationSelfVerifyWaitViewModelType
    private let keyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewController
    private let cancellable: Bool
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationSelfVerifyWaitCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isNewSignIn: Bool, cancellable: Bool) {
        self.session = session
        
        let keyVerificationSelfVerifyWaitViewModel = KeyVerificationSelfVerifyWaitViewModel(session: self.session, isNewSignIn: isNewSignIn)
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
    
    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didAcceptIncomingSASTransaction incomingSASTransaction: MXIncomingSASTransaction) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinator(self, didAcceptIncomingSASTransaction: incomingSASTransaction)
    }
    
    func keyVerificationSelfVerifyWaitViewModelDidCancel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinatorDidCancel(self)
    }
    
    func keyVerificationSelfVerifyWaitViewModel(_ coordinator: KeyVerificationSelfVerifyWaitViewModelType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode) {
        self.delegate?.keyVerificationSelfVerifyWaitCoordinator(self, wantsToRecoverSecretsWith: secretsRecoveryMode)
    }
}
