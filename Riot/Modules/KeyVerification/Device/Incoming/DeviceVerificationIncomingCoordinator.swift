// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
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

final class DeviceVerificationIncomingCoordinator: DeviceVerificationIncomingCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var deviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType
    private let deviceVerificationIncomingViewController: DeviceVerificationIncomingViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DeviceVerificationIncomingCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXSASTransaction) {
        self.session = session
        
        let deviceVerificationIncomingViewModel = DeviceVerificationIncomingViewModel(session: self.session, otherUser: otherUser, transaction: transaction)
        let deviceVerificationIncomingViewController = DeviceVerificationIncomingViewController.instantiate(with: deviceVerificationIncomingViewModel)
        self.deviceVerificationIncomingViewModel = deviceVerificationIncomingViewModel
        self.deviceVerificationIncomingViewController = deviceVerificationIncomingViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.deviceVerificationIncomingViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.deviceVerificationIncomingViewController
    }
}

// MARK: - DeviceVerificationIncomingViewModelCoordinatorDelegate
extension DeviceVerificationIncomingCoordinator: DeviceVerificationIncomingViewModelCoordinatorDelegate {
    
    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didAcceptTransaction transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationIncomingCoordinator(self, didAcceptTransaction: transaction)
    }
    
    func deviceVerificationIncomingViewModelDidCancel(_ viewModel: DeviceVerificationIncomingViewModelType) {
        self.delegate?.deviceVerificationIncomingCoordinatorDidCancel(self)
    }
}
