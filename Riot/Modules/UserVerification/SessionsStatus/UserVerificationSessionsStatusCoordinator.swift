// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
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

final class UserVerificationSessionsStatusCoordinator: UserVerificationSessionsStatusCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var userVerificationSessionsStatusViewModel: UserVerificationSessionsStatusViewModelType
    private let userVerificationSessionsStatusViewController: UserVerificationSessionsStatusViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationSessionsStatusCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, userId: String) {
        self.session = session
        
        let userVerificationSessionsStatusViewModel = UserVerificationSessionsStatusViewModel(session: self.session, userId: userId)
        let userVerificationSessionsStatusViewController = UserVerificationSessionsStatusViewController.instantiate(with: userVerificationSessionsStatusViewModel)
        self.userVerificationSessionsStatusViewModel = userVerificationSessionsStatusViewModel
        self.userVerificationSessionsStatusViewController = userVerificationSessionsStatusViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.userVerificationSessionsStatusViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.userVerificationSessionsStatusViewController
    }
}

// MARK: - UserVerificationSessionsStatusViewModelCoordinatorDelegate
extension UserVerificationSessionsStatusCoordinator: UserVerificationSessionsStatusViewModelCoordinatorDelegate {
    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didSelectDeviceWithId deviceId: String, for userId: String) {
        self.delegate?.userVerificationSessionsStatusCoordinator(self, didSelectDeviceWithId: deviceId, for: userId)
    }
    
    func userVerificationSessionsStatusViewModelDidClose(_ viewModel: UserVerificationSessionsStatusViewModelType) {
        self.delegate?.userVerificationSessionsStatusCoordinatorDidClose(self)
    }
}
