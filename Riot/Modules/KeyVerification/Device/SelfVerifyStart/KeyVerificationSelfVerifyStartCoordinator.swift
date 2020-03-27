// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
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
