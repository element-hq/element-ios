// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
/*
 Copyright 2019 New Vector Ltd
 
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
