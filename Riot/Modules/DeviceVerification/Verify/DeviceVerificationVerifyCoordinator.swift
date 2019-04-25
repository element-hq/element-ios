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

final class DeviceVerificationVerifyCoordinator: DeviceVerificationVerifyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var deviceVerificationVerifyViewModel: DeviceVerificationVerifyViewModelType
    private let deviceVerificationVerifyViewController: DeviceVerificationVerifyViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DeviceVerificationVerifyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, transaction: MXSASTransaction) {
        self.session = session
        
        let deviceVerificationVerifyViewModel = DeviceVerificationVerifyViewModel(session: self.session, transaction: transaction)
        let deviceVerificationVerifyViewController = DeviceVerificationVerifyViewController.instantiate(with: deviceVerificationVerifyViewModel)
        self.deviceVerificationVerifyViewModel = deviceVerificationVerifyViewModel
        self.deviceVerificationVerifyViewController = deviceVerificationVerifyViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.deviceVerificationVerifyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.deviceVerificationVerifyViewController
    }
}

// MARK: - DeviceVerificationVerifyViewModelCoordinatorDelegate
extension DeviceVerificationVerifyCoordinator: DeviceVerificationVerifyViewModelCoordinatorDelegate {

    func deviceVerificationVerifyViewModelDidComplete(_ viewModel: DeviceVerificationVerifyViewModelType) {
        self.delegate?.deviceVerificationVerifyCoordinatorDidComplete(self)
    }
    
    func deviceVerificationVerifyViewModelDidCancel(_ viewModel: DeviceVerificationVerifyViewModelType) {
        self.delegate?.deviceVerificationVerifyCoordinatorDidCancel(self)
    }
}
