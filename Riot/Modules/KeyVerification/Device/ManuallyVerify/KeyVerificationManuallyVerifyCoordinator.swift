// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
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
