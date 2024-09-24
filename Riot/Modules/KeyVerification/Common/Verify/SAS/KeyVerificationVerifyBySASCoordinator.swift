// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyVerificationVerifyBySASCoordinator: KeyVerificationVerifyBySASCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var keyVerificationVerifyViewModel: KeyVerificationVerifyBySASViewModelType
    private let keyVerificationVerifyViewController: KeyVerificationVerifyBySASViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationVerifyBySASCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, transaction: MXSASTransaction, verificationKind: KeyVerificationKind) {
        self.session = session
        
        let keyVerificationVerifyViewModel = KeyVerificationVerifyBySASViewModel(session: self.session, transaction: transaction, verificationKind: verificationKind)
        let keyVerificationVerifyViewController = KeyVerificationVerifyBySASViewController.instantiate(with: keyVerificationVerifyViewModel)
        self.keyVerificationVerifyViewModel = keyVerificationVerifyViewModel
        self.keyVerificationVerifyViewController = keyVerificationVerifyViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyVerificationVerifyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyVerificationVerifyViewController
    }
}

// MARK: - DeviceVerificationVerifyViewModelCoordinatorDelegate
extension KeyVerificationVerifyBySASCoordinator: KeyVerificationVerifyBySASViewModelCoordinatorDelegate {

    func keyVerificationVerifyViewModelDidComplete(_ viewModel: KeyVerificationVerifyBySASViewModelType) {
        self.delegate?.keyVerificationVerifyBySASCoordinatorDidComplete(self)
    }
    
    func keyVerificationVerifyViewModelDidCancel(_ viewModel: KeyVerificationVerifyBySASViewModelType) {
        self.delegate?.keyVerificationVerifyBySASCoordinatorDidCancel(self)
    }
}
