// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyVerificationManuallyVerifyCoordinator: KeyVerificationManuallyVerifyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var keyVerificationManuallyVerifyViewModel: KeyVerificationManuallyVerifyViewModelType
    private let keyVerificationManuallyVerifyViewController: KeyVerificationManuallyVerifyViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationManuallyVerifyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, deviceId: String, userId: String) {
        self.session = session
        
        let keyVerificationManuallyVerifyViewModel = KeyVerificationManuallyVerifyViewModel(session: self.session, deviceId: deviceId, userId: userId)
        let keyVerificationManuallyVerifyViewController = KeyVerificationManuallyVerifyViewController.instantiate(with: keyVerificationManuallyVerifyViewModel)
        self.keyVerificationManuallyVerifyViewModel = keyVerificationManuallyVerifyViewModel
        self.keyVerificationManuallyVerifyViewController = keyVerificationManuallyVerifyViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyVerificationManuallyVerifyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyVerificationManuallyVerifyViewController
    }
}

// MARK: - KeyVerificationManuallyVerifyViewModelCoordinatorDelegate
extension KeyVerificationManuallyVerifyCoordinator: KeyVerificationManuallyVerifyViewModelCoordinatorDelegate {
    
    func keyVerificationManuallyVerifyViewModel(_ viewModel: KeyVerificationManuallyVerifyViewModelType, didVerifiedDeviceWithId deviceId: String, of userId: String) {
        self.delegate?.keyVerificationManuallyVerifyCoordinator(self, didVerifiedDeviceWithId: deviceId, of: userId)
    }        
    
    func keyVerificationManuallyVerifyViewModelDidCancel(_ viewModel: KeyVerificationManuallyVerifyViewModelType) {
        self.delegate?.keyVerificationManuallyVerifyCoordinatorDidCancel(self)
    }
}
