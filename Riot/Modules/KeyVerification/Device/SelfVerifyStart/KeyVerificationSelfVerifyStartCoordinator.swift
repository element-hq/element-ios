// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyVerificationSelfVerifyStartCoordinator: KeyVerificationSelfVerifyStartCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var keyVerificationSelfVerifyStartViewModel: KeyVerificationSelfVerifyStartViewModelType
    private let keyVerificationSelfVerifyStartViewController: KeyVerificationSelfVerifyStartViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationSelfVerifyStartCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherDeviceId: String) {
        self.session = session
        
        let keyVerificationSelfVerifyStartViewModel = KeyVerificationSelfVerifyStartViewModel(session: self.session, otherDeviceId: otherDeviceId)
        let keyVerificationSelfVerifyStartViewController = KeyVerificationSelfVerifyStartViewController.instantiate(with: keyVerificationSelfVerifyStartViewModel)
        self.keyVerificationSelfVerifyStartViewModel = keyVerificationSelfVerifyStartViewModel
        self.keyVerificationSelfVerifyStartViewController = keyVerificationSelfVerifyStartViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyVerificationSelfVerifyStartViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyVerificationSelfVerifyStartViewController
    }
}

// MARK: - KeyVerificationSelfVerifyStartViewModelCoordinatorDelegate
extension KeyVerificationSelfVerifyStartCoordinator: KeyVerificationSelfVerifyStartViewModelCoordinatorDelegate {
    
    func keyVerificationSelfVerifyStartViewModel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.delegate?.keyVerificationSelfVerifyStartCoordinator(self, otherDidAcceptRequest: request)
    }
    
    func keyVerificationSelfVerifyStartViewModelDidCancel(_ viewModel: KeyVerificationSelfVerifyStartViewModelType) {
        self.delegate?.keyVerificationSelfVerifyStartCoordinatorDidCancel(self)
    }
}
