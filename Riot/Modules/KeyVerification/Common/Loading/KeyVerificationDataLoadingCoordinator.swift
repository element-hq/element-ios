// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

final class KeyVerificationDataLoadingCoordinator: KeyVerificationDataLoadingCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyVerificationDataLoadingViewModel: KeyVerificationDataLoadingViewModelType
    private let keyVerificationDataLoadingViewController: KeyVerificationDataLoadingViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationDataLoadingCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, verificationKind: KeyVerificationKind, otherUserId: String, otherDeviceId: String) {
        let keyVerificationDataLoadingViewModel = KeyVerificationDataLoadingViewModel(session: session, verificationKind: verificationKind, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
        let keyVerificationDataLoadingViewController = KeyVerificationDataLoadingViewController.instantiate(with: keyVerificationDataLoadingViewModel)
        self.keyVerificationDataLoadingViewModel = keyVerificationDataLoadingViewModel
        self.keyVerificationDataLoadingViewController = keyVerificationDataLoadingViewController
    }
    
    init(session: MXSession, verificationKind: KeyVerificationKind, incomingKeyVerificationRequest: MXKeyVerificationRequest) {
        let keyVerificationDataLoadingViewModel = KeyVerificationDataLoadingViewModel(session: session, verificationKind: verificationKind, keyVerificationRequest: incomingKeyVerificationRequest)
        let keyVerificationDataLoadingViewController = KeyVerificationDataLoadingViewController.instantiate(with: keyVerificationDataLoadingViewModel)
        self.keyVerificationDataLoadingViewModel = keyVerificationDataLoadingViewModel
        self.keyVerificationDataLoadingViewController = keyVerificationDataLoadingViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyVerificationDataLoadingViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyVerificationDataLoadingViewController
    }
}

// MARK: - KeyVerificationDataLoadingViewModelCoordinatorDelegate
extension KeyVerificationDataLoadingCoordinator: KeyVerificationDataLoadingViewModelCoordinatorDelegate {
    
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        self.delegate?.keyVerificationDataLoadingCoordinator(self, didAcceptKeyVerificationRequest: keyVerificationRequest)
    }    
    
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didAcceptKeyVerificationWithTransaction transaction: MXKeyVerificationTransaction) {
        self.delegate?.keyVerificationDataLoadingCoordinator(self, didAcceptKeyVerificationRequestWithTransaction: transaction)
    }
    
    func keyVerificationDataLoadingViewModel(_ viewModel: KeyVerificationDataLoadingViewModelType, didLoadUser user: MXUser, device: MXDeviceInfo) {
        self.delegate?.keyVerificationDataLoadingCoordinator(self, didLoadUser: user, device: device)
    }

    func keyVerificationDataLoadingViewModelDidCancel(_ viewModel: KeyVerificationDataLoadingViewModelType) {
        self.delegate?.keyVerificationDataLoadingCoordinatorDidCancel(self)
    }
}
