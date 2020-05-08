// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
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

final class UserVerificationSessionStatusCoordinator: UserVerificationSessionStatusCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let userId: String
    private let deviceId: String
    private var userVerificationSessionStatusViewModel: UserVerificationSessionStatusViewModelType
    private let userVerificationSessionStatusViewController: UserVerificationSessionStatusViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationSessionStatusCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, userId: String, userDisplayName: String?, deviceId: String) {
        self.session = session
        self.userId = userId
        self.deviceId = deviceId
        
        let userVerificationSessionStatusViewModel = UserVerificationSessionStatusViewModel(session: self.session, userId: userId, userDisplayName: userDisplayName, deviceId: deviceId)
        let userVerificationSessionStatusViewController = UserVerificationSessionStatusViewController.instantiate(with: userVerificationSessionStatusViewModel)
        self.userVerificationSessionStatusViewModel = userVerificationSessionStatusViewModel
        self.userVerificationSessionStatusViewController = userVerificationSessionStatusViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.userVerificationSessionStatusViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.userVerificationSessionStatusViewController
    }
}

// MARK: - UserVerificationSessionStatusViewModelCoordinatorDelegate
extension UserVerificationSessionStatusCoordinator: UserVerificationSessionStatusViewModelCoordinatorDelegate {
    
    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, wantsToVerifyDeviceWithId deviceId: String, for userId: String) {
        self.delegate?.userVerificationSessionStatusCoordinator(self, wantsToVerifyDeviceWithId: deviceId, for: userId)
    }
    
    func userVerificationSessionStatusViewModel(_ viewModel: UserVerificationSessionStatusViewModelType, wantsToManuallyVerifyDeviceWithId deviceId: String, for userId: String) {
        self.delegate?.userVerificationSessionStatusCoordinator(self, wantsToManuallyVerifyDeviceWithId: deviceId, for: userId)
    }
    
    func userVerificationSessionStatusViewModelDidClose(_ viewModel: UserVerificationSessionStatusViewModelType) {
        self.delegate?.userVerificationSessionStatusCoordinatorDidClose(self)
    }
}
