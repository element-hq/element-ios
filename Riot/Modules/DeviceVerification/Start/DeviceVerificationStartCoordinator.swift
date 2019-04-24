// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
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

final class DeviceVerificationStartCoordinator: DeviceVerificationStartCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var deviceVerificationStartViewModel: DeviceVerificationStartViewModelType
    private let deviceVerificationStartViewController: DeviceVerificationStartViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DeviceVerificationStartCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, otherDevice: MXDeviceInfo) {
        self.session = session
        
        let deviceVerificationStartViewModel = DeviceVerificationStartViewModel(session: self.session, otherUser: otherUser, otherDevice: otherDevice)
        let deviceVerificationStartViewController = DeviceVerificationStartViewController.instantiate(with: deviceVerificationStartViewModel)
        self.deviceVerificationStartViewModel = deviceVerificationStartViewModel
        self.deviceVerificationStartViewController = deviceVerificationStartViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.deviceVerificationStartViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.deviceVerificationStartViewController
    }
}

// MARK: - DeviceVerificationStartViewModelCoordinatorDelegate
extension DeviceVerificationStartCoordinator: DeviceVerificationStartViewModelCoordinatorDelegate {
    func deviceVerificationStartViewModelDidUseLegacyVerification(_ viewModel: DeviceVerificationStartViewModelType) {
        self.delegate?.deviceVerificationStartCoordinatorDidCancel(self) 
    }

    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationStartCoordinator(self, didCompleteWithOutgoingTransaction: transaction)
    }

    func deviceVerificationStartViewModel(_ viewModel: DeviceVerificationStartViewModelType, didTransactionCancelled transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationStartCoordinator(self, didTransactionCancelled: transaction)
    }
    
    func deviceVerificationStartViewModelDidCancel(_ viewModel: DeviceVerificationStartViewModelType) {
        self.delegate?.deviceVerificationStartCoordinatorDidCancel(self)
    }
}
